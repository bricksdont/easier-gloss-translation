#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation

scripts=$base/scripts
data=$base/data
translations=$base/translations
venvs=$base/venvs

source activate $venvs/sockeye3

python $scripts/deployment/export_as_html.py \
    --translations $translations/srf.dsgs-srf.de/emsl_v2a/srf.test.dsgs-de.de \
    --references $data/srf.dsgs-srf.de/emsl_v2a/srf.test.de
