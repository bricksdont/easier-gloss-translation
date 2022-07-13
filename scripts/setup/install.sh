#! /bin/bash

module load anaconda3 volta nvidia/cuda10.2-cudnn7.6.5

scripts=`dirname "$0"`
base=$scripts/../..

venvs=$base/venvs
tools=$base/tools

export TMPDIR="/var/tmp"

mkdir -p $tools

source activate $venvs/sockeye3

# install Sockeye

pip install sockeye==3.1.10

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece

# install tfds SL datasets

pip install sign-language-datasets==0.0.6

conda deactivate

source activate $venvs/huggingface3

# install pretraining code (HF transformers)

git clone https://github.com/huggingface/transformers $tools/transformers

(cd $tools/transformers && pip install .)

(cd $tools/transformers/examples/pytorch/translation && pip install -r requirements.txt)

# avoid protobuf error

pip install --upgrade protobuf~=3.19.0

# avoid problems caused by hard-coded behaviour to split language arguments at "_" characters:
# https://github.com/huggingface/transformers/blob/main/examples/pytorch/translation/run_translation.py#L427
# caution: this means MBART can no longer be used for this pretraining

sed -i 's/.split("_")\[0\]//g' $tools/transformers/examples/pytorch/translation/run_translation.py
