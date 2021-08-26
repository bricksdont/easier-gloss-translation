#! /bin/bash

module load anaconda3

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

# venv for Sockeye GPU

conda create -y --prefix $venvs/sockeye3 python=3.7.9

# different venv for Sockeye CPU

conda create -y --prefix $venvs/sockeye3-cpu python=3.7.9
