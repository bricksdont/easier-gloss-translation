#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $training_corpora
# $seed
# $bslcp_username
# $bslcp_password
# $use_mouthing_tier

base=$1
src=$2
trg=$3
model_name=$4
training_corpora=$5
seed=$6
bslcp_password=$7
bslcp_username=$8
use_mouthing_tier=$9

scripts=$base/scripts
data=$base/data
venvs=$base/venvs

mkdir -p $data

eval "$(conda shell.bash hook)"
source activate $venvs/sockeye3

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

TRAIN_SLICE_VERY_SMALL=100
TRAIN_SLICE_SMALL=1000
TRAIN_SLICE_MEDIUM=2500
TRAIN_SLICE_LARGE=5000

CORPORA_EXCEPT_TRAIN="dev test"

# download source, either "uhh" or "bslcp"

data_sub=$data/download

for source in $training_corpora; do

    data_sub_sub=$data_sub/$source

    if [[ -d $data_sub_sub ]]; then
        echo "data_sub_sub already exists: $data_sub_sub"
        echo "Skipping. Delete files to repeat step."
        continue
    fi

    mkdir -p $data_sub_sub

    if [[ $source == "uhh" ]]; then

        # download and extract data from UHH

        if [[ $use_mouthing_tier == "true" ]]; then
            use_mouthing_tier_arg="--use-mouthing-tier"
        else
            use_mouthing_tier_arg=""
        fi

        wget -N https://attachment.rrz.uni-hamburg.de/b026b8c8/pan.json -P $data_sub_sub

        python $scripts/download/extract_uhh.py \
            --pan-json $data_sub_sub/pan.json \
            --output-file $data_sub_sub/uhh.json \
            --tfds-data-dir $data/tfds $use_mouthing_tier_arg
    else
        # download and extract data from BSL corpus

        python $scripts/download/extract_bslcp.py \
            --output-file $data_sub_sub/bslcp.json \
            --tfds-data-dir $data/tfds \
            --bslcp-username $bslcp_username \
            --bslcp-password $bslcp_password
    fi

    # make fixed splits

    data_sub_sub=$data_sub/$source

    # set aside held-out slices of the training data (size of slice depending on total size)
    # for testing and development

    # determine $train_slice_size

    num_lines=$(cat $data_sub_sub/$source.json | wc -l)

    if [[ $num_lines -gt ${LARGEST_TRAINSIZE} ]]; then
        train_slice_size=$TRAIN_SLICE_LARGE
    elif [[ $num_lines -gt ${LARGE_TRAINSIZE} ]]; then
        train_slice_size=$TRAIN_SLICE_LARGE
    elif [[ $num_lines -gt ${MEDIUM_TRAINSIZE} ]]; then
        train_slice_size=$TRAIN_SLICE_LARGE
    elif [[ $num_lines -gt ${SMALL_TRAINSIZE} ]]; then
        train_slice_size=$TRAIN_SLICE_MEDIUM
    elif [[ $num_lines -gt ${SMALLEST_TRAINSIZE} ]]; then
        train_slice_size=$TRAIN_SLICE_SMALL
    else
        echo "Warning: training data size appears too small"
        train_slice_size=$TRAIN_SLICE_VERY_SMALL
    fi

    echo "train_slice_size=$train_slice_size"

    for slice_corpus in $CORPORA_EXCEPT_TRAIN; do

        # do not modify original download

        if [[ ! -f $data_sub_sub/train.json ]]; then

            python $scripts/preprocessing/shuffle_with_seed.py \
                --seed $seed --input $data_sub_sub/$source.json \
                > $data_sub_sub/train.json
        fi

        head -n $train_slice_size $data_sub_sub/train.json > $data_sub_sub/$slice_corpus.json

        # remove first $train_slice_size pairs from the training data

        sed -i -e 1,${train_slice_size}d $data_sub_sub/train.json

    done
done

echo "Sizes of files:"

wc -l $data_sub/*/*
