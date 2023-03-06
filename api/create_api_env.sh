#! /bin/bash

base=$(dirname "$0")
base=$(realpath "$base")

venvs=$base/venvs
tools=$base/tools

export TMPDIR="/var/tmp"

mkdir -p $venvs
mkdir -p $tools

# venv for Sockeye CPU

conda create -y --prefix $venvs/sockeye3 python=3.9.13

conda activate $venvs/sockeye3

# install Sockeye

pip install sockeye==3.1.31

# install sentencepiece for subword regularization

pip install sentencepiece

# flask server

pip install flask flask-cors
