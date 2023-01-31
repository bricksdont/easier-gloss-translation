# calling script needs to set:
# $base
# $language_pairs
# $model_name
# $training_corpora
# $testing_corpora
# $repeat_download_step

set -u

# construct src and trg from language_pairs

src=""
trg=""

for pair in "${language_pairs[@]}"; do
    pair=($pair)

    src=${src:+$src+}${pair[0]}.${pair[1]}
    trg=${trg:+$trg+}${pair[0]}.${pair[2]}
done

echo "REPEAT_DOWNLOAD_STEP: $repeat_download_step"

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

set +u
