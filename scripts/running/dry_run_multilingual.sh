#! /bin/bash

base=/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German
# En -> BSL

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh de dgs_de"
    "bslcp en bsl"
)

# dry runs of all steps

dry_run="true"

repeat_download_step="false"

# baseline

model_name="dry_run"

training_corpora="uhh bslcp"
testing_corpora="test"

multilingual="true"

bslcp_username=$BSLCP_USERNAME
bslcp_password=$BSLCP_PASSWORD

# this argument is for dry runs only, set to "true" to also repeat downloads (or linking)

repeat_download_step="false"

# delete files for this model to rerun everything

. $scripts/running/prompt_to_delete_dry_run_folders.sh

. $scripts/running/run_generic.sh
