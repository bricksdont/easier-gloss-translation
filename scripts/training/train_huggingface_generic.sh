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

prepared=$base/prepared
prepared_sub=$prepared/${src}-${trg}
prepared_sub_sub=$prepared_sub/$model_name

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

# assume model is bilingual and src and trg have a source first

src=$(echo $src | python -c "import sys; s = sys.stdin.read().strip(); print(s.split('.')[1])")
trg=$(echo $src | python -c "import sys; s = sys.stdin.read().strip(); print(s.split('.')[1])")

python $tools/transformers/examples/pytorch/translation/run_translation.py \
    --model_name_or_path $pretrained_model_name \
    --do_train \
    --do_eval \
    --source_lang $src \
    --target_lang $trg \
    --cache_dir $prepared_sub_sub \
    --train_file $data_sub_sub/train.json \
    --validation_file $data_sub_sub/dev.json \
    --output_dir $models_sub_sub \
    --per_device_train_batch_size=4 \
    --per_device_eval_batch_size=4 \
    --overwrite_output_dir \
    --max_target_length 250 \
    --seed $seed \
    --predict_with_generate $dry_run_additional_args
