#! /bin/bash

base=/net/cephfs/shares/volk.cl.uzh/mathmu/easier-gloss-translation
scripts=$base/scripts

# DGS -> German
# En -> BSL

# Structure: [source corpus] [src] [trg]

language_pairs=(
    "uhh de dgs_de"
    "bslcp en bsl"
)

# dry runs of all steps

dry_run="true"

repeat_download_step="true"

# baseline

model_name="dry_run"

training_corpora="uhh bslcp"
testing_corpora="test"

bslcp_username=$BSLCP_USERNAME
bslcp_password=$BSLCP_PASSWORD

# construct src and trg from language_pairs

src=""
trg=""

for pair in "${language_pairs[@]}"; do
    pair=($pair)

    src=${src:+$src+}${pair[0]}.${pair[1]}
    trg=${trg:+$trg+}${pair[0]}.${pair[2]}
done

# delete files for this model to rerun everything

sub_folders="data shared_models prepared models translations evaluations"

echo "Could delete the following folders related to $src-$trg/$model_name:"

for sub_folder in $sub_folders; do
  echo "$base/$sub_folder/$src-$trg/$model_name"
done

if [[ $repeat_download_step == "true" ]]; then
  for source in $training_corpora; do
    echo "$base/data/download/$source"
  done
fi

read -p "Delete? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for sub_folder in $sub_folders; do
      rm -rf $base/$sub_folder/$src-$trg/$model_name
    done

    if [[ $repeat_download_step == "true" ]]; then
      for source in $training_corpora; do
          rm -rf "$base/data/download/$source"
        done
    fi
fi

. $scripts/running/run_generic.sh
