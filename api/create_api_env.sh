#! /bin/bash

base=$(dirname "$0")
base=$(realpath "$base")

venvs=$base/venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

# venv for Sockeye CPU

conda create -y --prefix $venvs/sockeye3 python=3.9.13

export TMPDIR="/var/tmp"

mkdir -p $tools

source activate $venvs/sockeye3

# install Sockeye

pip install sockeye==3.1.31

# install Moses scripts for preprocessing

git clone https://github.com/bricksdont/moses-scripts $tools/moses-scripts

# install BPE library and sentencepiece for subword regularization

pip install subword-nmt sentencepiece

# install tfds SL datasets

# this currently fails until there is a new PyPi release

pip install sign-language-datasets==0.1.6

# install subtitles tool

pip install srt

# flask server

pip install flask flask-cors
