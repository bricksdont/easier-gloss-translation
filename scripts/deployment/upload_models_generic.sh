#! /bin/bash

# Calling script needs to set:
# $models
# $shared_models
# $deploy
# $deploy_name
# $langpair
# $model_name

relevant_files="args.yaml config log params.best version vocab.src.0.json vocab.trg.0.json"
relevant_files_spm="sentencepiece.model sentencepiece.vocab"

models_sub=$models/$langpair/$model_name
shared_models_sub=$shared_models/$langpair/$model_name
deploy_sub=$deploy/$deploy_name

mkdir -p $deploy_sub

for f in $relevant_files; do
    cp $models_sub/$f $deploy_sub/$f
done

for sf in $relevant_files_spm; do
    cp $shared_models_sub/$sf $deploy_sub/$sf
done

rm -f $deploy_sub.tar.gz

tar -czvf $deploy_sub.tar.gz $deploy_sub

chmod o+r $deploy_sub.tar.gz

scp $deploy_sub.tar.gz mmueller@home.ifi.uzh.ch:/srv/nfs/files/cl/archiv/2023/easier/$deploy_name.tar.gz
