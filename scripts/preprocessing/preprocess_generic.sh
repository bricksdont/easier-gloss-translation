#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $dry_run
# $seed
# $multilingual
# $language_pairs
# $spm_strategy

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
seed=$6
multilingual=$7
language_pairs=$8
spm_strategy=$9

data=$base/data
venvs=$base/venvs
scripts=$base/scripts
shared_models=$base/shared_models

mkdir -p $shared_models

# subfolders

data_sub=$data/${src}-${trg}
shared_models_sub=$shared_models/${src}-${trg}

# overwrite subfolder names to make it easier to read

data_sub=$data_sub/$model_name
shared_models_sub=$shared_models_sub/$model_name

mkdir -p $shared_models_sub

source activate $venvs/sockeye3

MOSES=$base/tools/moses-scripts/scripts
TOKENIZER=$MOSES/tokenizer

DRY_RUN_TRAIN_SIZE=14000
DRY_RUN_DEVTEST_SIZE=2

DEVTEST_MAXSIZE=5000

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

SENTENCEPIECE_MAX_LINES=10000000

CORPORA_EXCEPT_TRAIN="dev test"
ALL_CORPORA="$CORPORA_EXCEPT_TRAIN train"

echo "data_sub: $data_sub"

# measure time

SECONDS=0

#################

if [[ -f $data_sub/test.pieces.src ]]; then
    echo "File already exists: $data_sub/test.pieces.src"
    echo "Skipping. Delete files to repeat step."
    exit 0
fi

mkdir -p $data_sub

# extract data from download jsons

for pair in "${language_pairs[@]}"; do
    pair=($pair)

    source=${pair[0]}
    src=${pair[1]}
    trg=${pair[2]}

    download_sub=$data/download/$source

    for lang in $src $trg; do

        for corpus in $ALL_CORPORA; do
            python $scripts/preprocessing/extract_key_from_json.py \
                --input-file $download_sub/$corpus.json \
                --output-file $data_sub/$source.$corpus.$lang \
                --key $lang
        done
    done
done

# put together training data and correctly assign ".src" and ".trg" suffixes

for corpus in $ALL_CORPORA; do

    echo -n "" > $data_sub/$corpus.src
    echo -n "" > $data_sub/$corpus.trg

    for pair in "${language_pairs[@]}"; do
        pair=($pair)

        source=${pair[0]}
        src=${pair[1]}
        trg=${pair[2]}

        cat $data_sub/$source.$corpus.$src >> $data_sub/$corpus.src
        cat $data_sub/$source.$corpus.$trg >> $data_sub/$corpus.trg
    done
done

# truncate all data if dry run

if [[ $dry_run == "true" ]]; then
    for lang in src trg; do
        for corpus in $CORPORA_EXCEPT_TRAIN; do
            mv $data_sub/$corpus.$lang $data_sub/$corpus.$lang.big
            head -n $DRY_RUN_DEVTEST_SIZE $data_sub/$corpus.$lang.big > $data_sub/$corpus.$lang
        done

        mv $data_sub/train.$lang $data_sub/train.$lang.big
        head -n $DRY_RUN_TRAIN_SIZE $data_sub/train.$lang.big > $data_sub/train.$lang
    done
fi

# prenormalization for all corpora

for corpus in $ALL_CORPORA; do
    for lang in src trg; do
        cat $data_sub/$corpus.$lang | \
        perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' | \
        perl -CS -pe 's/\&\s*\#\s*160\s*\;/ /g' \
        > $data_sub/$corpus.prenorm.$lang
    done
done

# normalize train data

for lang in src trg; do
    cat $data_sub/train.prenorm.$lang | \
    ${TOKENIZER}/replace-unicode-punctuation.perl | \
    ${TOKENIZER}/remove-non-printing-char.perl | \
    ${TOKENIZER}/deescape-special-chars.perl | \
    sed 's/  */ /g;s/^ *//g;s/ *$//g' > \
        $data_sub/train.normalized.$lang
done

# normalize dev / test data

for corpus in $CORPORA_EXCEPT_TRAIN; do
    for lang in src trg; do
        cat $data_sub/$corpus.prenorm.$lang | \
        ${TOKENIZER}/replace-unicode-punctuation.perl | \
        ${TOKENIZER}/remove-non-printing-char.perl | \
        ${TOKENIZER}/deescape-special-chars.perl | \
        sed 's/  */ /g;s/^ *//g;s/ *$//g' > \
            $data_sub/$corpus.normalized.$lang
    done
done

# remove sentences from dev if source or target is empty
# (otherwise leads to potential Sockeye error)

for lang in src trg; do
    mv $data_sub/dev.normalized.$lang $data_sub/dev.before_remove_empty.$lang
done

python $scripts/preprocessing/remove_if_source_or_target_empty.py \
    --input-src $data_sub/dev.before_remove_empty.src \
    --input-trg $data_sub/dev.before_remove_empty.trg \
    --output-src $data_sub/dev.normalized.src \
    --output-trg $data_sub/dev.normalized.trg

# determine $sentencepiece_vocab_size

num_lines=$(cat $data_sub/train.normalized.src | wc -l)

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
    echo "Warning: training data size appears too small"
    sentencepiece_vocab_size=1000
fi

echo "sentencepiece_vocab_size=$sentencepiece_vocab_size"

# learn sentencepiece model(s) on train

if [[ $spm_strategy == "joint" ]]; then

    # one spm model overall

    cat $data_sub/train.normalized.src $data_sub/train.normalized.trg > $data_sub/train.normalized.both

    python $scripts/preprocessing/train_sentencepiece.py \
              --model-prefix $shared_models_sub/sentencepiece \
              --input $data_sub/train.normalized.both \
              --vocab-size $sentencepiece_vocab_size \
              --character-coverage 1.0 \
              --input-sentence-size=$SENTENCEPIECE_MAX_LINES

else
    # one spm model per side of parallel corpus

    for lang in src trg; do

        python $scripts/preprocessing/train_sentencepiece.py \
          --model-prefix $shared_models_sub/$lang.sentencepiece \
          --input $data_sub/train.normalized.$lang \
          --vocab-size $sentencepiece_vocab_size \
          --character-coverage 1.0 \
          --input-sentence-size=$SENTENCEPIECE_MAX_LINES
    done
fi

# apply SP model to train, test and dev

for corpus in $ALL_CORPORA; do
    for lang in src trg; do

        if [[ $spm_strategy == "joint" ]]; then
            spm_model=$shared_models_sub/sentencepiece.model
        else
            spm_model=$shared_models_sub/$lang.sentencepiece.model
        fi

        cat $data_sub/$corpus.normalized.$lang | \
            python $scripts/preprocessing/apply_sentencepiece.py \
                --model $spm_model \
                    > $data_sub/$corpus.pieces.$lang
    done
done

# ratio etc filter

$MOSES/training/clean-corpus-n.perl -ignore-ratio $data_sub/train.pieces src trg $data_sub/train.clean 1 250

# sizes
echo "Sizes of all files:"

wc -l $data_sub/*
wc -l $shared_models_sub/*

echo "time taken:"
echo "$SECONDS seconds"
