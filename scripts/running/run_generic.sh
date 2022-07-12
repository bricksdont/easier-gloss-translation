#! /bin/bash

# calling process needs to set:
# $base
# $language_pairs
# $model_name
#
# optional:
# $dry_run (values: "true" or "false")
# $training_corpora
# $testing_corpora
#
# $bslcp_username
# $bslcp_password
#
# $seed
# $multilingual (values: "true" or "false")
# $spm_strategy (values: "joint", "separate", "spoken-only")
# $lowercase_glosses (values: "true" or "false")
# $generalize_dgs_glosses (values: "true" or "false")
#
# $pretrained
# $pretrained_model_name

module load volta nvidia/cuda10.2-cudnn7.6.5 anaconda3

scripts=$base/scripts
logs=$base/logs

source activate $base/venvs/sockeye3

# construct src and trg from language_pairs

src=""
trg=""

for pair in "${language_pairs[@]}"; do
    pair=($pair)

    src=${src:+$src+}${pair[0]}.${pair[1]}
    trg=${trg:+$trg+}${pair[0]}.${pair[2]}
done

logs_sub=$logs/${src}-${trg}
logs_sub_sub=$logs_sub/$model_name

SLURM_DEFAULT_FILE_PATTERN="slurm-%j.out"
SLURM_LOG_ARGS="-o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN"

mkdir -p $logs_sub_sub

# if variables are undefined, set to avoid confusion

if [ -z "$dry_run" ]; then
    dry_run="false"
fi

if [ -z "$training_corpora" ]; then
    training_corpora="uhh"
fi

if [ -z "$testing_corpora" ]; then
    testing_corpora="test"
fi

if [ -z "$bslcp_username" ]; then
    bslcp_username="UNKNOWN"
fi

if [ -z "$bslcp_password" ]; then
    bslcp_password="UNKNOWN"
fi

if [ -z "$seed" ]; then
    seed="1"
fi

if [ -z "$multilingual" ]; then
    multilingual="false"
fi

if [ -z "$spm_strategy" ]; then
    spm_strategy="joint"
fi

if [ -z "$lowercase_glosses" ]; then
    lowercase_glosses="false"
fi

if [ -z "$generalize_dgs_glosses" ]; then
    generalize_dgs_glosses="false"
fi

if [ -z "$pretrained" ]; then
    pretrained="false"
fi

if [ -z "$pretrained_model_name" ]; then
    pretrained_model_name="mt5-small"
fi

# SLURM job args

DRY_RUN_SLURM_ARGS="--cpus-per-task=2 --time=02:00:00 --mem=16G --partition=generic"

SLURM_ARGS_GENERIC="--cpus-per-task=2 --time=24:00:00 --mem=16G --partition=generic"
SLURM_ARGS_VOLTA_TRAIN="--qos=vesta --time=36:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"
SLURM_ARGS_VOLTA_TRANSLATE="--qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"

# if dry run, then all args use generic instances

if [[ $dry_run == "true" ]]; then
  SLURM_ARGS_GENERIC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRAIN=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRANSLATE=$DRY_RUN_SLURM_ARGS
fi

# write langpairs array to executable file (workaround)

echo "${language_pairs[@]}" | python $scripts/running/construct_script_from_langpairs.py \
    > $logs_sub_sub/LANGPAIRS.sh

# log key info

echo "##############################################" | tee -a $logs_sub_sub/MAIN
date | tee -a $logs_sub_sub/MAIN
echo "##############################################" | tee -a $logs_sub_sub/MAIN
echo "LANGPAIR: ${src}-${trg}" | tee -a $logs_sub_sub/MAIN
echo "MODEL NAME: $model_name" | tee -a $logs_sub_sub/MAIN
echo "TRAINING CORPORA: $training_corpora" | tee -a $logs_sub_sub/MAIN
echo "TESTING CORPORA: $testing_corpora" | tee -a $logs_sub_sub/MAIN
echo "SEED: $seed" | tee -a $logs_sub_sub/MAIN
echo "MULTILINGUAL: $multilingual" | tee -a $logs_sub_sub/MAIN
echo "SPM_STRATEGY: $spm_strategy" | tee -a $logs_sub_sub/MAIN
echo "LOWERCASE_GLOSSES: $lowercase_glosses" | tee -a $logs_sub_sub/MAIN
echo "GENERALIZE_DGS_GLOSSES: $generalize_dgs_glosses" | tee -a $logs_sub_sub/MAIN
echo "DRY RUN: $dry_run" | tee -a $logs_sub_sub/MAIN

# download corpora

id_download=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    $SLURM_LOG_ARGS \
    $scripts/download/download_generic.sh \
    $base $src $trg $model_name "$training_corpora" $seed $bslcp_username $bslcp_password
)

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: Combine datasets, hold out data, normalize, SPM (depends on download)

id_preprocess=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_download \
    $SLURM_LOG_ARGS \
    $scripts/preprocessing/preprocess_generic.sh \
    $base $src $trg $model_name $dry_run $seed $multilingual $logs_sub_sub/LANGPAIRS.sh \
    $spm_strategy $lowercase_glosses $generalize_dgs_glosses $pretrained
)

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_preprocess \
    $SLURM_LOG_ARGS \
    $scripts/preprocessing/prepare_generic.sh \
    $base $src $trg $model_name $seed $spm_strategy $pretrained
)

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRAIN \
    --dependency=afterok:$id_prepare \
    $SLURM_LOG_ARGS \
    $scripts/training/train_generic.sh \
    $base $src $trg $model_name $dry_run $seed $spm_strategy $pretrained $pretrained_model_name
)

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate test set(s) (depends on train)

id_translate=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRANSLATE \
    --dependency=afterany:$id_train \
    $SLURM_LOG_ARGS \
    $scripts/translation/translate_generic.sh \
    $base $src $trg $model_name $dry_run "$testing_corpora" \
    $multilingual $logs_sub_sub/LANGPAIRS.sh $spm_strategy $pretrained $pretrained_model_name
)

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and other metrics (depends on translate)

id_evaluate=$(
    $scripts/running/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_translate \
    $SLURM_LOG_ARGS \
    $scripts/evaluation/evaluate_generic.sh \
    $base $src $trg $model_name "$testing_corpora" $logs_sub_sub/LANGPAIRS.sh $lowercase_glosses $generalize_dgs_glosses
)

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN
