#! /bin/bash

base=/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

# baseline

model_name="baseline_no_slurm"

training_corpora="uhh"
testing_corpora="test"

lowercase_glosses="false"
generalize_dgs_glosses="true"
spm_strategy="joint"

. $scripts/running/run_generic_no_slurm.sh
