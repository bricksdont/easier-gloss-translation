#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $dry_run
# $seed
# $multilingual
# $language_pairs (set by sourcing language_pairs_script)
# $spm_strategy
# $lowercase_glosses
# $generalize_dgs_glosses
# $use_mouthing_tier
# $casing_augmentation
# $emsl_version
# $emsl_threshold
# $emsl_i3d_model
# $emsl_add_comparable_data

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
seed=$6
multilingual=$7
language_pairs_script=$8
spm_strategy=$9
lowercase_glosses=${10}
generalize_dgs_glosses=${11}
use_mouthing_tier=${12}
casing_augmentation=${13}
emsl_version=${14}
emsl_threshold=${15}
emsl_i3d_model=${16}
emsl_add_comparable_data=${17}

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

echo "Python before activating:"
which python

echo "activate path:"
which activate

eval "$(conda shell.bash hook)"

echo "Executing: source activate $venvs/sockeye3"

source activate $venvs/sockeye3

echo "Python after activating:"
which python

MOSES=$base/tools/moses-scripts/scripts
TOKENIZER=$MOSES/tokenizer

DRY_RUN_TRAIN_SIZE=14000
DRY_RUN_DEVTEST_SIZE=2

SENTENCEPIECE_VOCAB_SIZE=1000

CORPORA_EXCEPT_TRAIN="dev test"
ALL_CORPORA="$CORPORA_EXCEPT_TRAIN train"

ALL_SOURCES="uhh bslcp srf"

GLOSS_SUFFIXES="dgs_de dgs_en bsl pan dsgs"
SPOKEN_SUFFIXES="de en"
ALL_SUFFIXES="$GLOSS_SUFFIXES $SPOKEN_SUFFIXES"

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

source $language_pairs_script

echo "language_pairs: "
echo "${language_pairs[@]}"

for pair in "${language_pairs[@]}"; do

    # if particular files appear several times in the array, processing happens twice which is negligible

    pair=($pair)

    source=${pair[0]}
    src=${pair[1]}
    trg=${pair[2]}

      echo "Found (source, src, trg): ($source, $src, $trg)"

    download_sub=$data/download/$source

    for lang in $src $trg; do

        # extract data from download jsons

        if [[ $use_mouthing_tier == "true" ]]; then
            use_mouthing_tier_arg="--use-mouthing-tier"
        else
            use_mouthing_tier_arg=""
        fi

        for corpus in $ALL_CORPORA; do

            if [[ $source == "srf" ]]; then

                # then assume the text strings should be taken from EMSL 2.0 data,
                # either v2.0a or v2.0b

                if [[ $emsl_version == "v2.0a" ]]; then

                    # there is only one version

                    emsl_folder=$download_sub/$emsl_version

                else
                    # assume version 2.0b
                    # find the correct combination of emsl version, i3d model and threshold

                    emsl_folder=$download_sub/$emsl_version/$emsl_i3d_model/$emsl_threshold

                fi

                if [[ $emsl_add_comparable_data == "true" ]]; then
                    input_file=$emsl_folder/all.$corpus.json
                else
                    input_file=$emsl_folder/parallel.$corpus.json
                fi
            else
                input_file=$download_sub/$corpus.json
            fi

            python $scripts/preprocessing/extract_key_from_json.py \
                --input-file $input_file \
                --output-file $data_sub/$source.$corpus.$lang \
                --key $lang $use_mouthing_tier_arg
        done

        # truncate all files if this is a dry run

        if [[ $dry_run == "true" ]]; then

            for corpus in $CORPORA_EXCEPT_TRAIN; do
                mv $data_sub/$source.$corpus.$lang $data_sub/$source.$corpus.$lang.big
                head -n $DRY_RUN_DEVTEST_SIZE $data_sub/$source.$corpus.$lang.big > $data_sub/$source.$corpus.$lang
            done

            mv $data_sub/$source.train.$lang $data_sub/$source.train.$lang.big
            head -n $DRY_RUN_TRAIN_SIZE $data_sub/$source.train.$lang.big > $data_sub/$source.train.$lang
        fi

        # if lang is a gloss suffix, possibly lowercase or other preprocessing
        # if lang is spoken suffix, this step does nothing

        for corpus in $ALL_CORPORA; do
            python $scripts/preprocessing/preprocess_glosses.py \
                --input-file $data_sub/$source.$corpus.$lang \
                --output-file $data_sub/$source.$corpus.preprocessed.$lang \
                --lang $lang \
                --lowercase-glosses $lowercase_glosses \
                --generalize-dgs-glosses $generalize_dgs_glosses $use_mouthing_tier_arg
        done

        # prenormalization for all corpora

        for corpus in $ALL_CORPORA; do
            cat $data_sub/$source.$corpus.preprocessed.$lang | \
            perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' | \
            perl -CS -pe 's/\&\s*\#\s*160\s*\;/ /g' \
            > $data_sub/$source.$corpus.prenorm.$lang
        done

        # normalize all corpora

        for corpus in $ALL_CORPORA; do
            cat $data_sub/$source.$corpus.prenorm.$lang | \
            ${TOKENIZER}/replace-unicode-punctuation.perl | \
            ${TOKENIZER}/remove-non-printing-char.perl | \
            ${TOKENIZER}/deescape-special-chars.perl | \
            sed 's/  */ /g;s/^ *//g;s/ *$//g' > \
                $data_sub/$source.$corpus.normalized.$lang
        done
    done

done

# potentially augment spoken language side with casing variants (training data only)

for pair in "${language_pairs[@]}"; do

    # if particular files appear several times in the array, processing happens twice which is negligible

    pair=($pair)

    source=${pair[0]}
    src=${pair[1]}
    trg=${pair[2]}

    for corpus in $ALL_CORPORA; do

        if [[ $corpus == "train" ]]; then

            if [[ $casing_augmentation == "true" ]]; then
                python $scripts/preprocessing/casing_augmentation.py \
                        --input-src $data_sub/$source.$corpus.normalized.$src \
                        --input-trg $data_sub/$source.$corpus.normalized.$trg \
                        --output-src $data_sub/$source.$corpus.post_casing_augmentation.$src \
                        --output-trg $data_sub/$source.$corpus.post_casing_augmentation.$trg \
                        --src-lang $src \
                        --trg-lang $trg
            else
                cp $data_sub/$source.$corpus.normalized.$src $data_sub/$source.$corpus.post_casing_augmentation.$src
                cp $data_sub/$source.$corpus.normalized.$trg $data_sub/$source.$corpus.post_casing_augmentation.$trg
            fi
        else
            cp $data_sub/$source.$corpus.normalized.$src $data_sub/$source.$corpus.post_casing_augmentation.$src
            cp $data_sub/$source.$corpus.normalized.$trg $data_sub/$source.$corpus.post_casing_augmentation.$trg
        fi
    done
done

# learn sentencepiece model(s) on train

if [[ $spm_strategy == "joint" || $spm_strategy == "spoken-only" ]]; then

    # then train one spm model overall

    if [[ $spm_strategy == "joint" ]]; then
        # use all post_casing_augmentation train files

        cat $data_sub/*.train.post_casing_augmentation.* > $data_sub/train.post_casing_augmentation.all
    else
        # $spm_strategy == "spoken-only"
        # use post_casing_augmentation train files for all spoken languages

        echo -n "" > $data_sub/train.post_casing_augmentation.all

        for source in $ALL_SOURCES; do
            for lang in $SPOKEN_SUFFIXES; do
                if [[ -f $data_sub/$source.train.post_casing_augmentation.$lang ]]; then
                  cat $data_sub/$source.train.post_casing_augmentation.$lang >> $data_sub/train.post_casing_augmentation.all
                fi
            done
        done
    fi

    input=$data_sub/train.post_casing_augmentation.all
    model_prefix=$shared_models_sub/sentencepiece

    . $scripts/preprocessing/train_sentencepiece_generic.sh

elif [[ $spm_strategy == "separate" ]]; then
    # one spm model for spoken, one for gloss suffixes

    echo -n "" > $data_sub/train.post_casing_augmentation.spoken
    echo -n "" > $data_sub/train.post_casing_augmentation.gloss

    for source in $ALL_SOURCES; do
        for lang in $SPOKEN_SUFFIXES; do
            if [[ -f $data_sub/$source.train.post_casing_augmentation.$lang ]]; then
              cat $data_sub/$source.train.post_casing_augmentation.$lang >> $data_sub/train.post_casing_augmentation.spoken
            fi
        done

        for lang in $GLOSS_SUFFIXES; do
            if [[ -f $data_sub/$source.train.post_casing_augmentation.$lang ]]; then
              cat $data_sub/$source.train.post_casing_augmentation.$lang >> $data_sub/train.post_casing_augmentation.gloss
            fi
        done
    done

    for suffix in spoken gloss; do

        input=$data_sub/train.post_casing_augmentation.$suffix
        model_prefix=$shared_models_sub/$suffix.sentencepiece

        . $scripts/preprocessing/train_sentencepiece_generic.sh

    done
else
    echo "ERROR: Unknown sentencepiece strategy: $spm_strategy"
    echo "Specify one of: 'joint', 'separate', 'spoken-only'"
    exit 1
fi

# apply SP models to train, test and dev

if [[ $spm_strategy == "joint" ]]; then

    for source in $ALL_SOURCES; do
        for corpus in $ALL_CORPORA; do
            for suffix in $ALL_SUFFIXES; do

                if [[ -f $data_sub/$source.$corpus.post_casing_augmentation.$suffix ]]; then
                    cat $data_sub/$source.$corpus.post_casing_augmentation.$suffix | \
                        python $scripts/preprocessing/apply_sentencepiece.py \
                            --model $shared_models_sub/sentencepiece.model \
                                > $data_sub/$source.$corpus.pieces.$suffix
                fi
            done
        done
    done

elif [[ $spm_strategy == "spoken-only" ]]; then

    for source in $ALL_SOURCES; do
        for corpus in $ALL_CORPORA; do
            for suffix in $SPOKEN_SUFFIXES; do

                if [[ -f $data_sub/$source.$corpus.post_casing_augmentation.$suffix ]]; then
                    cat $data_sub/$source.$corpus.post_casing_augmentation.$suffix | \
                        python $scripts/preprocessing/apply_sentencepiece.py \
                            --model $shared_models_sub/sentencepiece.model \
                                > $data_sub/$source.$corpus.pieces.$suffix
                fi
            done

            for suffix in $GLOSS_SUFFIXES; do

                if [[ -f $data_sub/$source.$corpus.post_casing_augmentation.$suffix ]]; then
                    # applying spm model is a no-op for gloss data in this case

                    cp $data_sub/$source.$corpus.post_casing_augmentation.$suffix $data_sub/$source.$corpus.pieces.$suffix
                fi
            done
        done
    done

else
    # $spm_strategy == "separate"
    for source in $ALL_SOURCES; do
        for corpus in $ALL_CORPORA; do
            for suffix in $SPOKEN_SUFFIXES; do

                if [[ -f $data_sub/$source.$corpus.post_casing_augmentation.$suffix ]]; then
                    cat $data_sub/$source.$corpus.post_casing_augmentation.$suffix | \
                        python $scripts/preprocessing/apply_sentencepiece.py \
                            --model $shared_models_sub/spoken.sentencepiece.model \
                                > $data_sub/$source.$corpus.pieces.$suffix
                fi
            done

            for suffix in $GLOSS_SUFFIXES; do

                if [[ -f $data_sub/$source.$corpus.post_casing_augmentation.$suffix ]]; then
                    cat $data_sub/$source.$corpus.post_casing_augmentation.$suffix | \
                        python $scripts/preprocessing/apply_sentencepiece.py \
                            --model $shared_models_sub/gloss.sentencepiece.model \
                                > $data_sub/$source.$corpus.pieces.$suffix
                fi
            done
        done
    done
fi

# put together training data and correctly assign ".src" and ".trg" suffixes

for corpus in $ALL_CORPORA; do

    echo -n "" > $data_sub/$corpus.pieces.src
    echo -n "" > $data_sub/$corpus.pieces.trg

    for pair in "${language_pairs[@]}"; do
        pair=($pair)

        source=${pair[0]}
        src=${pair[1]}
        trg=${pair[2]}

        if [[ $multilingual == "true" ]]; then
             cat $data_sub/$source.$corpus.pieces.$src | \
                 python $scripts/preprocessing/add_tag_to_lines.py --tag "<2$trg>" \
                     > $data_sub/$source.$corpus.tag.$src

             cat $data_sub/$source.$corpus.tag.$src >> $data_sub/$corpus.pieces.src
        else
             cat $data_sub/$source.$corpus.pieces.$src >> $data_sub/$corpus.pieces.src
        fi
        cat $data_sub/$source.$corpus.pieces.$trg >> $data_sub/$corpus.pieces.trg
    done
done

# ratio etc filter for train

$MOSES/training/clean-corpus-n.perl -ignore-ratio $data_sub/train.pieces src trg $data_sub/train.clean 1 250

# remove sentences from dev if source or target is empty
# (otherwise leads to potential Sockeye error)

for corpus in dev; do
    for lang in src trg; do
        mv $data_sub/$corpus.pieces.$lang $data_sub/$corpus.pieces.before_remove_empty.$lang
    done

    python $scripts/preprocessing/remove_if_source_or_target_empty.py \
        --input-src $data_sub/$corpus.pieces.before_remove_empty.src \
        --input-trg $data_sub/$corpus.pieces.before_remove_empty.trg \
        --output-src $data_sub/$corpus.pieces.src \
        --output-trg $data_sub/$corpus.pieces.trg
done

# sizes
echo "Sizes of all files:"

wc -l $data_sub/*
wc -l $shared_models_sub/*

echo "time taken:"
echo "$SECONDS seconds"
