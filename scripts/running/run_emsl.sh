#! /bin/bash

base=/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DSGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "srf dsgs de"
)

# baseline

model_name="emsl_v2"

training_corpora="srf"
testing_corpora="test"

. $scripts/running/run_generic.sh
