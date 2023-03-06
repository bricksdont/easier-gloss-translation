#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/../..

venvs=$base/venvs

export TMPDIR="/var/tmp"

models=$base/models

mkdir -p $models

MODEL_URL="https://files.ifi.uzh.ch/cl/archiv/2022/easier/dgs_de.tar.gz"

wget $MODEL_URL -P $models

(cd $models && tar -xzvf dgs_de.tar.gz)

ls -l $models
ls -l $models/*
