# calling script needs to set:
# $base
# $base_scripts
# $langpair
# $model_name
# $src
# $trg
# $corpus

scripts=$base_scripts/scripts
data=$base/data
translations=$base/translations
venvs=$base_scripts/venvs
deploy=$base/deploy

html_name="$langpair+$model_name.html"

xml_url="https://files.ifi.uzh.ch/cl/archiv/2023/easier/final_eval/signed-to-spoken/$src-$trg/dataset.xml"

data_sub=$data/$langpair/$model_name
translations_sub=$translations/$langpair/$model_name
deploy_sub=$deploy/$langpair/$model_name

mkdir -p $deploy_sub

source activate $venvs/sockeye3

# naming schemes:
# - sources: srf.test.dsgs
# -translations: srf.test.dsgs-de.de
# - references: srf.test.de

sources=$data_sub/$corpus.test.$src
translations=$translations_sub/$corpus.test.$src-$trg.$trg
references=$data_sub/$corpus.test.$trg

python $scripts/deployment/export_as_html.py \
    --xml-url $xml_url \
    --sources $sources \
    --translations $translations \
    --references $references \
    > $deploy_sub/$html_name

echo "Saved to"
echo "$deploy_sub/$html_name"

# upload

ssh mmueller@files.ifi.uzh.ch "mkdir -p /srv/nfs/files/cl/archiv/2023/easier/final_eval/$src-$trg"

scp $deploy_sub/$html_name mmueller@files.ifi.uzh.ch:/srv/nfs/files/cl/archiv/2023/easier/final_eval/$src-$trg/$html_name

ssh mmueller@files.ifi.uzh.ch "chmod a+r /srv/nfs/files/cl/archiv/2023/easier/final_eval/$src-$trg/$html_name"

echo "Uploaded to"
echo "https://files.ifi.uzh.ch/cl/archiv/2023/easier/final_eval/signed-to-spoken/bsl-en/$html_name"
