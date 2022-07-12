#!/bin/bash

# calling script needs to set:

# $base
# $src
# $trg
# $model_name
# $dry_run
# $seed
# $spm_strategy
# $pretrained
# $pretrained_model_name

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
seed=$6
spm_strategy=$7
pretrained=$8
pretrained_model_name=$9

scripts=$base/scripts

if [[ $pretrained == "true" ]]; then

  . $scripts/training/train_huggingface_generic.sh

else

  . $scripts/training/train_sockeye_generic.sh

fi
