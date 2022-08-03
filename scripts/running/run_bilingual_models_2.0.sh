#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

lowercase_glosses="true"
generalize_dgs_glosses="true"
spm_strategy="joint"

dry_run="false"

model_name="2.0"

## UHH

training_corpora="uhh"

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

. $scripts/running/run_generic.sh


# German -> DGS

language_pairs=(
    "uhh de dgs_de"
)

. $scripts/running/run_generic.sh
