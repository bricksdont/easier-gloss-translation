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

## Train and evaluate all bilingual models

    ./scripts/running/run_bilingual_models.sh

## Train and evaluate all multilingual models

    ./scripts/running/run_bilingual_models.sh

## Define a custom run

Construct a new top-level file similar to the existing files in `scripts/running`. Most importantly, define how the training, 
dev and test data should be composed by assigning the variable `language_pairs`:

    language_pairs=(
    "uhh de dgs_de"
    "bslcp en bsl"
    )

The structure of each row in this array is `[source corpus] [src] [trg]`, and there can be arbitrarily many rows.

- Your custom running script must eventually call `$scripts/running/run_generic.sh`
- Set `multilingual` if MT system needs an indication of desired target language (i.e. if there are several target languages)
- If data from both UHH and BSLCP is used, set `training_corpora="uhh bslcp"`
- Before training an actual model, set `dry_run="true"` to test your setup

## Create and upload a summary of all experiment outcomes

    ./scripts/summaries/summarize.sh
   
## Create result tables shown in the deliverable

https://colab.research.google.com/drive/1xDOkBI3yOoKk1CI_BBZoLtVWAaY0uhWd?usp=sharing