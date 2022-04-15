#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $testing_corpora
# $language_pairs (set by sourcing language_pairs_script)

base=$1
src=$2
trg=$3
model_name=$4
testing_corpora=$5
language_pairs_script=$6

venvs=$base/venvs
scripts=$base/scripts

source activate $venvs/sockeye3

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mbr=$base/mbr
mbr_sub=$mbr/${src}-${trg}
mbr_sub_sub=$mbr_sub/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

source $language_pairs_script

# compute case-sensitive BLEU and CHRF on detokenized data

chrf_beta=2

for pair in "${language_pairs[@]}"; do

    pair=($pair)

    source=${pair[0]}
    src=${pair[1]}
    trg=${pair[2]}

    for corpus in $testing_corpora; do

        ref=$data_sub_sub/$source.$corpus.$trg

        hyp=$translations_sub_sub/$source.$corpus.$src-$trg.$trg
        output_prefix=$evaluations_sub_sub/$source.$corpus.$src-$trg

        output=$output_prefix.bleu

        . $scripts/evaluation/evaluate_bleu_more_generic.sh

        output=$output_prefix.chrf

        . $scripts/evaluation/evaluate_chrf_more_generic.sh

    done
done
