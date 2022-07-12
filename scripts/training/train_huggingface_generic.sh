#!/bin/bash

# calling script needs to set:

# $base
# $src
# $trg
# $model_name
# $dry_run
# $seed
# $pretrained_model_name

venvs=$base/venvs
tools=$base/tools

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

models=$base/models
models_sub=$models/${src}-${trg}
models_sub_sub=$models_sub/$model_name

mkdir -p $models_sub_sub

eval "$(conda shell.bash hook)"
source activate $venvs/huggingface3

if [[ $dry_run == "true" ]]; then
    dry_run_additional_args="--max_train_samples 10 --no_cuda"
else
    dry_run_additional_args=""
fi

# check if training is finished

if [[ -f $models_sub_sub/log ]]; then

    # TODO! adapt to HF

    training_finished=`grep "Training finished" $models_sub_sub/log | wc -l`

    if [[ $training_finished != 0 ]]; then
        echo "Training is finished"
        echo "Skipping. Delete files to repeat step."
        exit 0
    fi
fi

python $tools/transformers/examples/pytorch/translation/run_translation.py \
    --model_name_or_path $pretrained_model_name \
    --do_train \
    --do_eval \
    --source_lang $src \
    --target_lang $trg \
    --dataset_name $model_name \
    --dataset_config_name $model_name \
    --train_file $data_sub_sub/train.jsonl \
    --validation_file $data_sub_sub/dev.jsonl \
    --output_dir $models_sub_sub \
    --per_device_train_batch_size=4 \
    --per_device_eval_batch_size=4 \
    --overwrite_output_dir \
    --max_target_length 250 \
    --seed $seed \
    --predict_with_generate $dry_run_additional_args
