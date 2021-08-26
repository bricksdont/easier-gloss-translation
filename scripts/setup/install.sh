#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs
tools=$base/tools

export TMPDIR="/var/tmp"

mkdir -p $tools

source $venvs/sockeye3/bin/activate

# install Sockeye 2 GPU

# CUDA version on instance
CUDA_VERSION=112

git clone https://github.com/bricksdont/sockeye $tools/sockeye

(cd $tools/sockeye && git checkout continuous_inputs )
(cd $tools/sockeye && pip install . --no-deps --no-cache-dir -r requirements/requirements.gpu-cu${CUDA_VERSION}.txt )

pip install matplotlib mxboard requests

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece

################################################

deactivate

# install Sockeye 2 CPU

source $venvs/sockeye3-cpu/bin/activate

(cd $tools/sockeye && pip install . --no-deps --no-cache-dir -r requirements/requirements.txt )

pip install matplotlib mxboard requests

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece
