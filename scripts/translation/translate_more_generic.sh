#! /bin/bash

# calling script needs to set

# $input
# $output_pieces
# $output
# $length_penalty_alpha
# $models_sub_sub
# $dry_run
# $beam_size
# $batch_size
# $multilingual
# $spm_strategy
# $trg

if [[ $dry_run == "true" ]]; then
    # redefine params
    beam_size=1
    batch_size=2
    dry_run_additional_args="--use-cpu"
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

    # 1-best translation with beam

    OMP_NUM_THREADS=1 python -m sockeye.translate \
            -i $input \
            -o $output_pieces \
            -m $models_sub_sub \
            --beam-size $beam_size \
            --length-penalty-alpha $length_penalty_alpha \
            --device-id 0 \
            --batch-size $batch_size $dry_run_additional_args

    # undo pieces

    cat $output_pieces | sed 's/ //g;s/▁/ /g' > $output

    # except if target is glosses and the gloss side was never segmented

    if [[ $trg == "dgs_de" || $trg == "dgs_en" || $trg == "pan" || $trg == "bsl" ]]; then
        if [[ $spm_strategy == "spoken-only" ]]; then
            cat $output_pieces | sed 's/ //g;s/▁/ /g' > $output
        fi
    fi

done