#! /bin/bash

module load v100-32g cuda/11.6.2 cudnn/8.4.0.27-11.6 anaconda3

scripts=`dirname "$0"`
base=$scripts/../..

venvs=$base/venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

# venv for Sockeye GPU

conda create -y --prefix $venvs/sockeye3 python=3.9.13
