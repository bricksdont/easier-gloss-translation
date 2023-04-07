#! /bin/bash

base=$(dirname "$0")
base=$(realpath "$base")

export TMPDIR="/var/tmp"

models=$base/models

mkdir -p $models

MODEL_URLS="https://files.ifi.uzh.ch/cl/archiv/2022/easier/dgs_de.tar.gz https://files.ifi.uzh.ch/cl/archiv/2023/easier/dgs_de_augmented.tar.gz"

for model_url in $MODEL_URLS; do
    wget $model_url -P $models
done

(cd $models && tar -xzvf dgs_de.tar.gz)
(cd $models && tar -xzvf dgs_de_augmented.tar.gz)

ls -l $models
ls -l $models/*
