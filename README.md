# EASIER gloss translation models

## Basic setup

Create a venv:

    ./scripts/setup/create_venv.sh

Then install required software:

    ./scripts/setup/install.sh

If the BSL corpus is used as training data, `BSLCP_USERNAME` and `BSLCP_USERNAME` must be set as environment
variables before submitting any runs.

## Dry run

Try to create all files and run all scripts, but on CPU only and exit immediately without any actual computation:

    ./scripts/running/dry_run_baseline.sh

## Run a bilingual baseline

Train a baseline system for DGS -> DE:

    ./scripts/running/run_baseline.sh

## Train all bilingual models

    ./scripts/running/run_bilingual_models.sh

## Define a custom run

- Set `multilingual` if MT system needs an indication of desired target language (i.e. if there are several target languages)
- If data from both UHH and BSLCP is used, set `training_corpora="uhh bslcp`