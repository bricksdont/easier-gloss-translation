#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# TODO: decide lg

lowercase_glosses="true false"
generalize_dgs_glosses="false"
spm_strategy="joint"

dry_run="true"

testing_corpora="test"

multilingual="true"

# all German and DGS directions

training_corpora="uhh"

language_pairs=(
    "uhh dgs_de de"
    "uhh de dgs_de"
)

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

. $scripts/running/run_generic.sh

# all directions from UHH

training_corpora="uhh"

language_pairs=(
    "uhh dgs_de de"
    "uhh dgs_de en"
    "uhh dgs_de dgs_en"
    "uhh de dgs_de"
    "uhh de dgs_en"
    "uhh de en"
    "uhh dgs_en de"
    "uhh dgs_en dgs_de"
    "uhh dgs_en en"
)

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

. $scripts/running/run_generic.sh

# all directions from BSLCP

training_corpora="bslcp"

language_pairs=(
    "bslcp bsl en"
    "bslcp en bsl"
)

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

. $scripts/running/run_generic.sh

# all English and BSL + translated DGS glosses directions

training_corpora="uhh bslcp"

language_pairs=(
    "bslcp bsl en"
    "bslcp en bsl"
    "uhh dgs_en en"
    "uhh en dgs_en"
)

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

. $scripts/running/run_generic.sh

# ALL directions

training_corpora="uhh bslcp"

language_pairs=(
    "uhh dgs_de de"
    "uhh dgs_de en"
    "uhh dgs_de dgs_en"
    "uhh de dgs_de"
    "uhh de dgs_en"
    "uhh de en"
    "uhh dgs_en de"
    "uhh dgs_en dgs_de"
    "uhh dgs_en en"
    "bslcp bsl en"
    "bslcp en bsl"
)

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

. $scripts/running/run_generic.sh