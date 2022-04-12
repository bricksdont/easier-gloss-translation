#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $training_corpora
# $bslcp_username
# $bslcp_password

base=$1
src=$2
trg=$3
model_name=$4
training_corpora=$5
bslcp_username=$6
bslcp_password=$7

scripts=$base/scripts
data=$base/data
venvs=$base/venvs

mkdir -p $data

source activate $venvs/sockeye3

data_sub=$data/download

# source either "uhh" or "bslcp"

for source in $training_corpora; do

    data_sub_sub=$data_sub/$source

    if [[ -d $data_sub_sub ]]; then
        echo "data_sub_sub already exists: $data_sub_sub"
        echo "Skipping. Delete files to repeat step."
        exit 0
    fi

    mkdir -p $data_sub_sub

    if [[ $source == "uhh" ]]; then

        # download and extract data from UHH

        wget -N https://attachment.rrz.uni-hamburg.de/b026b8c8/pan.json -P $data_sub_sub

        python $scripts/download/extract_uhh.py \
            --pan-json $data_sub_sub/pan.json \
            --output-file $data_sub_sub/uhh.json \
            --tfds-data-dir $data/tfds
    else
        # download and extract data from BSL corpus

        python $scripts/download/extract_bslcp.py \
            --output-folder $data_sub_sub \
            --tfds-data-dir $data/tfds \
            --bslcp-username $bslcp_username \
            --bslcp-password $bslcp_password
    fi
done

echo "Sizes of files:"

wc -l $data_sub_sub/*
