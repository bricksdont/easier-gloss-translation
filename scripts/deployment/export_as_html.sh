#! /bin/bash

module load anaconda3

base=/shares/volk.cl.uzh/arios/easier-gloss-translation
base_scripts=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation

deploy=$base/deploy

mkdir -p $deploy

# constant for all language pairs

model_names="emsl_v2b+threshold.0.5+i3d.dgs+lowercase.true+add_comparable.true emsl_v2b+threshold.0.5+i3d.bsl+lowercase.true+add_comparable.true emsl_v2b+threshold.0.5+i3d.both+lowercase.true+add_comparable.true"

for model_name in $model_names; do

    # DSGS -> DE

    src="dsgs"
    trg="de"
    corpus="srf"
    langpair="srf.dsgs-srf.de"

    . $base_scripts/scripts/deployment/export_as_html_generic.sh

    # DGS -> DE

    src="dgs"
    trg="de"
    corpus="web"
    langpair="dgs_web.dgs_de-dgs_web.de"

    . $base_scripts/scripts/deployment/export_as_html_generic.sh

    # LSF -> FR

    src="lsf"
    trg="fr"
    corpus="rts"
    langpair="rts.lsf-rts.fr"

    . $base_scripts/scripts/deployment/export_as_html_generic.sh

    # LIS -> IT

    src="lis"
    trg="it"
    corpus="rsi"
    langpair="rsi.lis-rsi.it"

    . $base_scripts/scripts/deployment/export_as_html_generic.sh

done

# for BSL-EN, just one model exists

model_name="emsl_v2b+lowercase.true+add_comparable.true"

src="bsl"
trg="en"
corpus="bobsl"
langpair="bobsl.bsl-bobsl.en"

. $base_scripts/scripts/deployment/export_as_html_generic.sh
