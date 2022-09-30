#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

lowercase_glosses="true"
generalize_dgs_glosses="true"
spm_strategy="joint"

dry_run="false"

testing_corpora="test"

multilingual="true"

if [[ $dry_run == "true" ]]; then
    model_name="dry_run"
else
    model_name="multilingual.true+lg.$lowercase_glosses+gdg.$generalize_dgs_glosses+ss.$spm_strategy"
fi

# all German and DGS directions

training_corpora="uhh"

language_pairs=(
    "uhh dgs_de de"
    "uhh de dgs_de"
)

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
    "uhh en de"
    "uhh en dgs_de"
    "uhh en dgs_en"
)

. $scripts/running/run_generic.sh

# all directions from BSLCP

training_corpora="bslcp"

language_pairs=(
    "bslcp bsl en"
    "bslcp en bsl"
)

. $scripts/running/run_generic.sh

# all English and BSL + translated DGS glosses directions

training_corpora="uhh bslcp"

language_pairs=(
    "bslcp bsl en"
    "bslcp en bsl"
    "uhh dgs_en en"
    "uhh en dgs_en"
)

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
    "uhh en de"
    "uhh en dgs_de"
    "uhh en dgs_en"
    "bslcp bsl en"
    "bslcp en bsl"
)

. $scripts/running/run_generic.sh
