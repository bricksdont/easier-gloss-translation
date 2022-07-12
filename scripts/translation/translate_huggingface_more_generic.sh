#! /bin/bash

# calling script needs to set

# $input
# $output
# $models_sub_sub
# $dry_run
# $src
# $trg
# $pretrained_model_name

if [[ $dry_run == "true" ]]; then
    # redefine params
    beam_size=1
    batch_size=2
    dry_run_additional_args="--device cpu"
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

    python $tools/transformers/transformers/examples/pytorch/translation/run_translation.py \
        --model_name_or_path $pretrained_model_name \
        --output_dir $models_sub_sub \
        --do_predict \
        --test-file $input \
        --num_beams $beam_size \
        --source_lang $src \
        --target_lang $trg \
        --dataset_name $model_name \
        --dataset_config_name $model_name \
        --output_dir $models_sub_sub \
        --per_device_eval_batch_size=$batch_size \
        --seed $seed \
        --predict_with_generate $dry_run_additional_args

    # HF handles segmentation internally, no need to undo pieces

    # move hard-coded output file, see
    # https://github.com/huggingface/transformers/blob/main/examples/pytorch/translation/run_translation.py#L625

    mv $models_sub_sub/generated_predictions.txt $output

done