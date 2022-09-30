#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

lowercase_glosses="true"
generalize_dgs_glosses="true"
spm_strategy="joint"

dry_run="false"

## UHH

training_corpora="uhh"

dgs_use_document_split="true"

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

for use_mouthing_tier in true false; do

    model_name="dgs_use_document_split.true+use_mouthing_tier.$use_mouthing_tier"

    . $scripts/running/run_generic.sh

done

# German -> DGS

language_pairs=(
    "uhh de dgs_de"
)

model_name="dgs_use_document_split.true"

. $scripts/running/run_generic.sh
