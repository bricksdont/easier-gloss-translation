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
# $dgs_use_document_split

base=$1
src=$2
trg=$3
model_name=$4
training_corpora=$5
seed=$6
bslcp_password=$7
bslcp_username=$8
dgs_use_document_split=$9

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

# download source, currently either "uhh", "bslcp" or "srf"

# in the case of "srf", no need to download, will link locally from our storage

EMSL_BASE="/shares/easier.volk.cl.uzh/WP4/spoken-to-sign_sign-to-spoken/DSGS/SRF/Daily_news/emsl"

SRF_SUBTITLES_PARALLEL_TRAIN_DIR="/shares/easier.volk.cl.uzh/WMT_Shared_Task/srf/parallel/subtitles"
SRF_SUBTITLES_PARALLEL_DEV_DIR="/shares/easier.volk.cl.uzh/WMT_Shared_Task/dev/dsgs-de/subtitles"
SRF_SUBTITLES_PARALLEL_TEST_DIR="/shares/easier.volk.cl.uzh/WMT_Shared_Task/test/dsgs-de/subtitles"

SRF_SUBTITLES_COMPARABLE_TRAIN_DIR="/shares/easier.volk.cl.uzh/WP4/spoken-to-sign_sign-to-spoken/DSGS/SRF/Daily_news/subtitles_sentence-segmented_Surrey"

data_sub=$data/download

for source in $training_corpora; do

    data_sub_sub=$data_sub/$source

    if [[ -d $data_sub_sub ]]; then
        echo "data_sub_sub already exists: $data_sub_sub"
        echo "Skipping. Delete files to repeat step."
        continue
    fi

    mkdir -p $data_sub_sub

    if [[ $source == "srf" ]]; then

        # 1. version 2.0a

        # only one sub-version of v2.0a

        EMSL_DIR=$EMSL_BASE/v2.0a

        data_sub_sub_sub=$data_sub_sub/v2.0a

        mkdir -p $data_sub_sub_sub

        # only one sub-version of v2.0a

        python $scripts/download/assemble_emsl_v2.py \
            --emsl-dir-train $EMSL_DIR/train \
            --emsl-dir-dev $EMSL_DIR/dev \
            --emsl-dir-test $EMSL_DIR/test \
            --subtitles-dir-train $SRF_SUBTITLES_PARALLEL_TRAIN_DIR \
            --subtitles-dir-dev $SRF_SUBTITLES_PARALLEL_DEV_DIR \
            --subtitles-dir-test $SRF_SUBTITLES_PARALLEL_TEST_DIR \
            --output-dir $data_sub_sub_sub \
            --src-lang dsgs \
            --trg-lang de \
            --emsl-version v2.0a

        # 2. version 2.0b

        EMSL_DIR_SHARED_TASK=$EMSL_BASE/v2.0b/shared_task
        EMSL_DIR_BROADCAST=$EMSL_BASE/v2.0b/broadcast

        data_sub_sub_sub=$data_sub_sub/v2.0b

        mkdir -p $data_sub_sub_sub

        for i3d_model in bsl dgs both; do
            for threshold in 0.5 0.6 0.7 0.8; do

                data_unique_combination=$data_sub_sub_sub/$i3d_model/$threshold

                mkdir -p $data_unique_combination

                i3d_origin_name=$(python $scripts/download/map_emsl_versions.py $i3d_model)
                threshold_origin_name=$(python $scripts/download/map_emsl_versions.py $threshold)

                EMSL_DIR_PARALLEL=$EMSL_DIR_SHARED_TASK/$i3d_origin_name/$threshold_origin_name
                EMSL_DIR_COMPARABLE=$EMSL_DIR_BROADCAST/$i3d_origin_name/$threshold_origin_name

                python $scripts/download/assemble_emsl_v2.py \
                    --emsl-dir-train $EMSL_DIR_PARALLEL/train \
                    --emsl-dir-dev $EMSL_DIR_PARALLEL/dev \
                    --emsl-dir-test $EMSL_DIR_PARALLEL/test \
                    --subtitles-dir-train $SRF_SUBTITLES_PARALLEL_TRAIN_DIR \
                    --subtitles-dir-dev $SRF_SUBTITLES_PARALLEL_DEV_DIR \
                    --subtitles-dir-test $SRF_SUBTITLES_PARALLEL_TEST_DIR \
                    --output-dir $data_unique_combination \
                    --src-lang dsgs \
                    --trg-lang de \
                    --output-prefix parallel \
                    --emsl-version v2.0b

                # comparable data where subtitles are not human-corrected

                python $scripts/download/assemble_emsl_v2.py \
                    --emsl-dir-train $EMSL_DIR_COMPARABLE \
                    --subtitles-dir-train $SRF_SUBTITLES_COMPARABLE_TRAIN_DIR \
                    --output-dir $data_unique_combination \
                    --src-lang dsgs \
                    --trg-lang de \
                    --output-prefix comparable \
                    --emsl-version v2.0b

                # concat all subsets, for debugging

                cat $data_unique_combination/{train,dev,test}.parallel.json > $data_unique_combination/srf.parallel.json
                cat $data_unique_combination/{train,dev,test}.comparable.json > $data_unique_combination/srf.comparable.json

                cat $data_unique_combination/srf.parallel.json $data_unique_combination/srf.comparable.json > $data_unique_combination/srf.json
            done
        done

    elif [[ $source == "uhh" ]]; then

        # download and extract data from UHH

        wget -N https://attachment.rrz.uni-hamburg.de/b026b8c8/pan.json -P $data_sub_sub

        if [[ $dgs_use_document_split == "true" ]]; then
            use_document_split_arg="--use-document-split"
        else
            use_document_split_arg=""
        fi

        python $scripts/download/extract_uhh.py \
            --pan-json $data_sub_sub/pan.json \
            --output-file-train $data_sub_sub/train.json \
            --output-file-dev $data_sub_sub/dev.json \
            --output-file-test $data_sub_sub/test.json \
            --tfds-data-dir $data/tfds $use_document_split_arg

        # concat all subsets, for debugging

        cat $data_sub_sub/{train,dev,test}.json > $data_sub_sub/uhh.json

    else
        # download and extract data from BSL corpus

        python $scripts/download/extract_bslcp.py \
            --output-file $data_sub_sub/bslcp.json \
            --tfds-data-dir $data/tfds \
            --bslcp-username $bslcp_username \
            --bslcp-password $bslcp_password

        # make fixed splits, but only if this is not DGS with a fixed, existing split

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
    fi
done

echo "Sizes of files:"

wc -l $data_sub/*/*/*/*
