#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
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

# construct src and trg from language_pairs

src=""
trg=""

for pair in "${language_pairs[@]}"; do
    pair=($pair)

    src=${src:+$src+}${pair[0]}.${pair[1]}
    trg=${trg:+$trg+}${pair[0]}.${pair[2]}
done

# delete files for this model to rerun everything

. $scripts/running/prompt_to_delete_dry_run_folders.sh

. $scripts/running/run_generic.sh
