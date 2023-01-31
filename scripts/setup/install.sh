#! /bin/bash

module load v100-32g cuda/11.6.2 cudnn/8.4.0.27-11.6 anaconda3

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

# this currently fails until there is a new PyPi release

pip install sign-language-datasets==0.1.2

# install subtitles tool

pip install srt
