#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/sockeye-sign-translation-scripts
scripts=$base/scripts

# DGS -> German

src=dgs
trg=de

# baseline

model_name="baseline"

corpora="test"

. $scripts/running/run_generic.sh
