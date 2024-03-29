#!/bin/bash

# calling script needs to set:

# $base
# $src
# $trg
# $model_name
# $dry_run
# $seed
# $spm_strategy

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
seed=$6
spm_strategy=$7

venvs=$base/venvs

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
source activate $venvs/sockeye3

# parameters are the same for all Transformer models

num_embed="512:512"
num_layers="6:6"
transformer_model_size="512"
transformer_attention_heads="8"
transformer_feed_forward_num_hidden="2048"

# parameters vary depending on training data size

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

num_lines=$(cat $data_sub_sub/train.clean.src | wc -l)

if [[ $num_lines -gt ${LARGEST_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${LARGE_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${MEDIUM_TRAINSIZE} ]]; then
    embed_dropout=0.1
    transformer_dropout=0.1
    batch_size=4096
    decode_and_evaluate=2500
    checkpoint_interval=5000
elif [[ $num_lines -gt ${SMALL_TRAINSIZE} ]]; then
    embed_dropout=0.2
    transformer_dropout=0.2
    batch_size=2048
    decode_and_evaluate=1000
    checkpoint_interval=1000
elif [[ $num_lines -gt ${SMALLEST_TRAINSIZE} ]]; then
    embed_dropout=0.5
    transformer_dropout=0.5
    batch_size=1024
    decode_and_evaluate=500
    checkpoint_interval=1000
else
    echo "Warning: training data size appears too small to train a model"
    embed_dropout=0.5
    transformer_dropout=0.5
    batch_size=1024
    decode_and_evaluate=1000
    checkpoint_interval=1000
fi

# check if training is finished

if [[ -f $models_sub_sub/log ]]; then

    training_finished=`grep "Training finished" $models_sub_sub/log | wc -l`

    if [[ $training_finished != 0 ]]; then
        echo "Training is finished"
        echo "Skipping. Delete files to repeat step."
        exit 0
    fi
fi

if [[ $dry_run == "true" ]]; then
    dry_run_additional_args="--max-updates 10 --use-cpu"
    checkpoint_interval=10
    num_embed="64:64"
    num_layers="6:6"
    transformer_model_size="64"
    transformer_attention_heads="1"
    transformer_feed_forward_num_hidden="64"
else
    dry_run_additional_args=""
fi

if [[ $spm_strategy == "joint" ]]; then
    weight_tying_arg="src_trg_softmax"
else
    weight_tying_arg="trg_softmax"
fi

##################################################

python -m sockeye.train \
-d $prepared_sub_sub \
-vs $data_sub_sub/dev.pieces.src \
-vt $data_sub_sub/dev.pieces.trg \
--output $models_sub_sub \
--seed $seed \
--batch-type word \
--batch-size $batch_size \
--device-id 0 \
--encoder transformer \
--decoder transformer \
--num-layers $num_layers \
--transformer-model-size $transformer_model_size \
--transformer-attention-heads $transformer_attention_heads \
--transformer-feed-forward-num-hidden $transformer_feed_forward_num_hidden \
--transformer-preprocess n \
--transformer-postprocess dr \
--transformer-dropout-attention $transformer_dropout \
--transformer-dropout-act $transformer_dropout \
--transformer-dropout-prepost $transformer_dropout \
--transformer-positional-embedding-type fixed \
--embed-dropout $embed_dropout:$embed_dropout \
--weight-tying-type $weight_tying_arg \
--num-embed $num_embed \
--num-words 64000:64000 \
--optimizer adam \
--initial-learning-rate 0.0001 \
--learning-rate-reduce-num-not-improved 8 \
--checkpoint-interval $checkpoint_interval \
--keep-last-params 30 \
--max-seq-len 250:250 \
--learning-rate-reduce-factor 0.7 \
--decode-and-evaluate $decode_and_evaluate \
--max-num-checkpoint-not-improved 32 \
--min-num-epochs 0 \
--gradient-clipping-type abs \
--gradient-clipping-threshold 1 $dry_run_additional_args
