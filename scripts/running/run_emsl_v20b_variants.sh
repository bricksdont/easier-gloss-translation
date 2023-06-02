#! /bin/bash

base=/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DSGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "srf dsgs de"
)

# ("srf" implies EMSL 2.0, because no other gloss data is available for the SRF corpus)

# test various combinations of options

training_corpora="srf"
testing_corpora="dev test"

spm_strategy="joint"

emsl_version="v2.0b"

# not worth testing without lowercasing

lowercase_glosses_options="true"

emsl_add_comparable_data_options="false true"

emsl_i3d_models="bsl dgs both"
emsl_thresholds="0.5 0.6 0.7 0.8"

for emsl_threshold in $emsl_thresholds; do
    for emsl_i3d_model in $emsl_i3d_models; do
        for lowercase_glosses in $lowercase_glosses_options; do
            for emsl_add_comparable_data in $emsl_add_comparable_data_options; do
                model_name="emsl_v2b+threshold.$emsl_threshold+i3d.$emsl_i3d_model+lowercase.$lowercase_glosses+add_comparable.$emsl_add_comparable_data"

                . $scripts/running/run_generic.sh
            done
        done
    done
done
