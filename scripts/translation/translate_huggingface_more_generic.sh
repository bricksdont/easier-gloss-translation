#! /bin/bash

# calling script needs to set

# $base
# $input
# $output
# $models_sub_sub
# $dry_run
# $src
# $trg
# $pretrained_model_name

prepared=$base/prepared
prepared_sub=$prepared/${src}-${trg}
prepared_sub_sub=$prepared_sub/$model_name

tools=$base/tools

if [[ $dry_run == "true" ]]; then
    # redefine params
    beam_size=1
    batch_size=2
    dry_run_additional_args="--no_cuda"
else
    dry_run_additional_args=""
fi

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      echo "Translations exist: $output"

      num_lines_input=$(cat $input | wc -l)
      num_lines_output=$(cat $output | wc -l)

      if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$input == $output"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
      else
          echo "$input != $output"
          echo "$num_lines_input != $num_lines_output"
          echo "Repeating step."
      fi
    fi

    python $tools/transformers/examples/pytorch/translation/run_translation.py \
        --model_name_or_path $pretrained_model_name \
        --output_dir $models_sub_sub \
        --cache_dir $prepared_sub_sub \
        --do_predict \
        --test-file $input \
        --num_beams $beam_size \
        --source_lang $src \
        --target_lang $trg \
        --output_dir $models_sub_sub \
        --per_device_eval_batch_size=$batch_size \
        --predict_with_generate $dry_run_additional_args

    # HF handles segmentation internally, no need to undo pieces

    # move hard-coded output file, see
    # https://github.com/huggingface/transformers/blob/main/examples/pytorch/translation/run_translation.py#L625

    mv $models_sub_sub/generated_predictions.txt $output

done