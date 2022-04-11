#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German

src=dgs
trg=de

# baseline

model_name="baseline"

training_corpora="uhh"
testing_corpora="test"

. $scripts/running/run_generic.sh
