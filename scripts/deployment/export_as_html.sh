#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation

scripts=$base/scripts
data=$base/data
translations=$base/translations
venvs=$base/venvs
deploy=$base/deploy

mkdir -p $deploy
mkdir -p $deploy/html_export

source activate $venvs/sockeye3

python $scripts/deployment/export_as_html.py \
    --translations $translations/srf.dsgs-srf.de/emsl_v2a/srf.test.dsgs-de.de \
    --references $data/srf.dsgs-srf.de/emsl_v2a/srf.test.de \
    > $deploy/html_export/emsl_v2a.html

echo "Saved to"
echo "$deploy/html_export/emsl_v2a.html"

ssh mmueller@home.ifi.uzh.ch 'chmod a+r /home/files/cl/archiv/2023/easier/emsl_v2a.html'

# upload

# scp $deploy/html_export/emsl_v2a.html mmueller@home.ifi.uzh.ch:/home/files/cl/archiv/2023/easier/emsl_v2a.html
