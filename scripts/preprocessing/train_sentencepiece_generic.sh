#! /bin/bash

# calling script needs to set

# $scripts
# $input
# $model_prefix

SENTENCEPIECE_MAX_LINES=10000000

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

# determine $sentencepiece_vocab_size

num_lines=$(cat $input | wc -l)

if [[ $num_lines -gt ${LARGEST_TRAINSIZE} ]]; then
    sentencepiece_vocab_size=16000
elif [[ $num_lines -gt ${LARGE_TRAINSIZE} ]]; then
    sentencepiece_vocab_size=16000
elif [[ $num_lines -gt ${MEDIUM_TRAINSIZE} ]]; then
    sentencepiece_vocab_size=12000
elif [[ $num_lines -gt ${SMALL_TRAINSIZE} ]]; then
    sentencepiece_vocab_size=4000
elif [[ $num_lines -gt ${SMALLEST_TRAINSIZE} ]]; then
    sentencepiece_vocab_size=1000
else
    echo "Warning: training data size appears too small for an SPM model"
    sentencepiece_vocab_size=1000
fi

echo "sentencepiece_vocab_size=$sentencepiece_vocab_size"

# learn sentencepiece model

python $scripts/preprocessing/train_sentencepiece.py \
    --model-prefix $model_prefix \
    --input $input \
    --vocab-size $sentencepiece_vocab_size \
    --character-coverage 1.0 \
    --input-sentence-size=$SENTENCEPIECE_MAX_LINES
