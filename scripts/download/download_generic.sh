#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $sources
# $bslcp_username
# $bslcp_password

base=$1
src=$2
trg=$3
model_name=$4
sources=$5

scripts=$base/scripts
data=$base/data
venvs=$base/venvs

mkdir -p $data

source activate $venvs/sockeye3

data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

if [[ -d $data_sub_sub ]]; then
    echo "data_sub_sub already exists: $data_sub_sub"
    echo "Skipping. Delete files to repeat step."
    exit 0
fi

mkdir -p $data_sub_sub

for source in $sources; do
    if [[ $source == "uhh" ]]; then

        # download and extract data from UHH

        wget -N https://attachment.rrz.uni-hamburg.de/b026b8c8/pan.json -P $data_sub_sub

        python $scripts/download/extract_uhh.py \
            --input-file $data_sub_sub/pan.json \
            --output-folder $data_sub_sub
    else
        # download and extract data from BSL corpus

        python $scripts/download/extract_bslcp.py \
            --output-folder $data_sub_sub \
            --tfds-data-dir $data_sub_sub/tfds \
            --bslcp-username $bslcp_username \
            --bslcp-password $bslcp_password
    fi
done

echo "Sizes of files:"

wc -l $data_sub_sub/*
