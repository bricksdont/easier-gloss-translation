#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

# baseline

model_name="pretrained"

training_corpora="uhh"
testing_corpora="test"

pretrained="true"
pretrained_model_name="google/mt5-small"

. $scripts/running/run_generic.sh
