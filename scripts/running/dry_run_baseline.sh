#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh dgs de"
)

# dry runs of all steps

dry_run="true"

# baseline

model_name="dry_run"

training_corpora="uhh"
testing_corpora="test"

# delete files for this model to rerun everything

sub_folders="data shared_models prepared models translations evaluations"

echo "Could delete the following folders related to $src-$trg/$model_name:"

for sub_folder in $sub_folders; do
  echo "$base/$sub_folder/$src-$trg/$model_name"
done

read -p "Delete? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for sub_folder in $sub_folders; do
      rm -rf $base/$sub_folder/$src-$trg/$model_name
    done
fi

. $scripts/running/run_generic.sh
