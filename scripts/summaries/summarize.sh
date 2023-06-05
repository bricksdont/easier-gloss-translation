#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation

venvs=$base/venvs
scripts=$base/scripts
evaluations=$base/evaluations

summaries=$base/summaries

mkdir -p $summaries

python3 $scripts/summaries/summarize.py --eval-folder $evaluations > $summaries/summary.tsv

# upload to home.ifi.uzh.ch

scp $summaries/summary.tsv \
    mmueller@files.ifi.uzh.ch:/home/files/cl/archiv/2022/easier/gloss_translation_models_summary.tsv
