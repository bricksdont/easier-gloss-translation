#! /bin/bash

# calling process needs to set:
# $base
# $src
# $trg
# $model_name
#
# optional:
# $train_additional_args
# $preprocess_execute_more_mem
# $dry_run
# $corpora
# $preprocess_create_slice_dev
# $train_dev_corpus
# $preprocess_additional_test_corpora

module load volta cuda/11.2 anaconda3

scripts=$base/scripts
logs=$base/logs

source activate $base/venvs/sockeye3-cpu

logs_sub=$logs/${src}-${trg}
logs_sub_sub=$logs_sub/$model_name

SLURM_DEFAULT_FILE_PATTERN="slurm-%j.out"
SLURM_LOG_ARGS="-o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN"

mkdir -p $logs_sub_sub

# if variables are undefined, set to avoid confusion

if [ -z "$dry_run" ]; then
    dry_run="false"
fi

if [ -z "$corpora" ]; then
    corpora="test"
fi

if [ -z "$train_additional_args" ]; then
    train_additional_args=""
fi

if [ -z "$preprocess_execute_more_mem" ]; then
    preprocess_execute_more_mem="false"
fi

if [ -z "$preprocess_additional_test_corpora" ]; then
    preprocess_additional_test_corpora=""
fi

# SLURM job args

DRY_RUN_SLURM_ARGS="--cpus-per-task=2 --time=02:00:00 --mem=16G --partition=generic"

SLURM_ARGS_GENERIC="--cpus-per-task=2 --time=24:00:00 --mem=16G --partition=generic"
SLURM_ARGS_GENERIC_MEM="--cpus-per-task=2 --time=24:00:00 --mem=32G --partition=generic"
SLURM_ARGS_GENERIC_LARGE="--cpus-per-task=32 --time=24:00:00 --mem=32G --partition=generic"
SLURM_ARGS_GENERIC_LARGE_LONG="--cpus-per-task=32 --time=96:00:00 --mem=32G --partition=generic"
SLURM_ARGS_HPC="--cpus-per-task=32 --time=72:00:00 --mem=32G --partition=hpc"
SLURM_ARGS_VOLTA_TRAIN="--qos=vesta --time=72:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"
SLURM_ARGS_VOLTA_TRANSLATE="--qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"

if [[ $preprocess_execute_more_mem == "true" ]]; then
  SLURM_ARGS_PREPROCESS=$SLURM_ARGS_GENERIC_MEM
else
  SLURM_ARGS_PREPROCESS=$SLURM_ARGS_GENERIC
fi

# if dry run, then all args use generic instances

if [[ $dry_run == "true" ]]; then
  SLURM_ARGS_GENERIC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRAIN=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRANSLATE=$DRY_RUN_SLURM_ARGS
fi

# log key info

echo "##############################################" | tee -a $logs_sub_sub/MAIN
date | tee -a $logs_sub_sub/MAIN
echo "##############################################" | tee -a $logs_sub_sub/MAIN
echo "LANGPAIR: ${src}-${trg}" | tee -a $logs_sub_sub/MAIN
echo "MODEL NAME: $model_name" | tee -a $logs_sub_sub/MAIN
echo "TEST CORPORA: $corpora" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS EXECUTE MORE MEM: $preprocess_execute_more_mem" | tee -a $logs_sub_sub/MAIN
echo "ADDITIONAL TRAIN ARGS: $train_additional_args" | tee -a $logs_sub_sub/MAIN
echo "DRY RUN: $dry_run" | tee -a $logs_sub_sub/MAIN

# download corpus for language pair

id_download=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg $model_name
)

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: Hold out data, normalize, SPM, maybe insert copy noise (depends on download)

id_preprocess=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_PREPROCESS \
    --dependency=afterok:$id_download \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg $model_name $dry_run "$preprocess_additional_test_corpora"
)

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_preprocess \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name
)

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRAIN \
    --dependency=afterok:$id_prepare \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args" $dry_run
)

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate test set(s) (depends on train)

id_translate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRANSLATE \
    --dependency=afterany:$id_train \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name $dry_run "$corpora"
)

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and other metrics (depends on translate)

id_evaluate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_translate \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg $model_name "$corpora"
)

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN
