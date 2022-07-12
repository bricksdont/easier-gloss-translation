#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $dry_run
# $testing_corpora
# $multilingual
# $language_pairs (set by sourcing language_pairs_script)
# $spm_strategy

venvs=$base/venvs
scripts=$base/scripts

eval "$(conda shell.bash hook)"
source activate $venvs/sockeye3

beam_size="5"
batch_size="64"
length_penalty_alpha="1.0"

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

models=$base/models
models_sub=$models/${src}-${trg}
models_sub_sub=$models_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

# fail with non-zero status if there is no model checkpoint,
# to signal to downstream dependencies that they cannot be satisfied

if [[ ! -e $models_sub_sub/params.best ]]; then
    echo "There is no single model checkpoint, file does not exist:"
    echo "$models_sub_sub/params.best"
    exit 1
fi

mkdir -p $translations_sub_sub

source $language_pairs_script

# beam translation for all language pairs

for pair in "${language_pairs[@]}"; do

    pair=($pair)

    source=${pair[0]}
    src=${pair[1]}
    trg=${pair[2]}

    for corpus in $testing_corpora; do

        if [[ $multilingual == "true" ]]; then
            input=$data_sub_sub/$source.$corpus.tag.$src
        else
            input=$data_sub_sub/$source.$corpus.pieces.$src
        fi
        output_pieces=$translations_sub_sub/$source.$corpus.pieces.$src-$trg.$trg
        output=$translations_sub_sub/$source.$corpus.$src-$trg.$trg

        . $scripts/translation/translate_sockeye_more_generic.sh
    done
done
