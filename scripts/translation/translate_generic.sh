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
# $pretrained
# $pretrained_model_name

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
testing_corpora=$6
multilingual=$7
language_pairs_script=$8
spm_strategy=$9
pretrained=${10}
$pretrained_model_name=${11}

scripts=$base/scripts

if [[ $pretrained == "true" ]]; then

  . $scripts/translation/translate_huggingface_generic.sh

else

  . $scripts/translation/translate_sockeye_generic.sh

fi