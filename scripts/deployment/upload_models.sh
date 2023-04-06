#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation

scripts=$base/scripts
models=$base/models
shared_models=$base/shared_models
deploy=$base/deploy

mkdir -p $deploy

# new augmented model

model_name="multilingual.true+lg.true+gdg.true+ss.joint+casing_augmentation"

deploy_name="dgs_de_augmented"
langpair="uhh.dgs_de+uhh.de-uhh.de+uhh.dgs_de"

. $scripts/deployment/upload_models_generic.sh

# TODO: remove

exit

model_name="multilingual.true+lg.true+gdg.true+ss.joint"

# DGS

deploy_name="dgs_de"
langpair="uhh.dgs_de+uhh.de-uhh.de+uhh.dgs_de"

. $scripts/deployment/upload_models_generic.sh

# BSL

deploy_name="bsL_en"
langpair="bslcp.bsl+bslcp.en-bslcp.en+bslcp.bsl"

. $scripts/deployment/upload_models_generic.sh
