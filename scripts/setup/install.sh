#! /bin/bash

module load anaconda3 volta nvidia/cuda11.2-cudnn8.1.0

scripts=`dirname "$0"`
base=$scripts/../..

venvs=$base/venvs
tools=$base/tools

export TMPDIR="/var/tmp"

mkdir -p $tools

source activate $venvs/sockeye3

# install Sockeye

# CUDA version on instance
CUDA_VERSION=112

pip install sockeye

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece
