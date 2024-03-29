#! /bin/bash

base=/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

# baseline

model_name="baseline"

training_corpora="uhh"
testing_corpora="test"

. $scripts/running/run_generic.sh
