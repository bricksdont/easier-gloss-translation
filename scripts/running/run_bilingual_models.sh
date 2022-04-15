#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

lowercase_glosses_options="true false"
generalize_dgs_glosses_options="true false"
spm_strategy_options="joint separate spoken-only"

dry_run="true"

## UHH

training_corpora="uhh"

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs_de de"
)

for lowercase_gloss in $lowercase_glosses_options; do
    for generalize_dgs_glosses in $generalize_dgs_glosses_options; do
        for spm_strategy in $spm_strategy_options; do

            model_name="lg.$lowercase_gloss+gdg.$generalize_dgs_glosses+ss.$spm_strategy"

            . $scripts/running/run_generic.sh

        done
    done
done

# German -> DGS

language_pairs=(
    "uhh de dgs_de"
)

for lowercase_gloss in $lowercase_glosses_options; do
    for generalize_dgs_glosses in $generalize_dgs_glosses_options; do
        for spm_strategy in $spm_strategy_options; do

            model_name="lg.$lowercase_gloss+gdg.$generalize_dgs_glosses+ss.$spm_strategy"

            . $scripts/running/run_generic.sh

        done
    done
done

## BSLCP

training_corpora="bslcp"

# BSL -> English

language_pairs=(
    "bslcp bsl en"
)

for lowercase_gloss in $lowercase_glosses_options; do
    for spm_strategy in $spm_strategy_options; do

        model_name="lg.$lowercase_gloss+ss.$spm_strategy"

        . $scripts/running/run_generic.sh

    done
done

# English -> BSL

language_pairs=(
    "bslcp en bsl"
)

for lowercase_gloss in $lowercase_glosses_options; do
    for spm_strategy in $spm_strategy_options; do

        model_name="lg.$lowercase_gloss+ss.$spm_strategy"

        . $scripts/running/run_generic.sh

    done
done
