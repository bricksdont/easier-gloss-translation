#! /usr/bin/python3

import argparse
import logging
import json


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-src", type=str, help="Source input file", required=True)
    parser.add_argument("--input-trg", type=str, help="Target input file", required=True)

    parser.add_argument("--src-lang", type=str, help="Source language", required=True)
    parser.add_argument("--trg-lang", type=str, help="Target language", required=True)

    parser.add_argument("--output", type=str, help="Output JSON lines", required=True)

    args = parser.parse_args()

    return args


def undo_pieces(input_string: str) -> str:

    input_string = input_string.strip()

    input_string = input_string.replace(" ", "")
    input_string = input_string.replace("▁", " ")

    # remove initial space if any

    input_string = input_string.lstrip()

    return input_string


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    with open(args.input_src, "r") as handle_input_src, \
            open(args.input_trg, "r") as handle_input_trg, \
            open(args.output, "w") as handle_output:

        for src_line, trg_line in zip(handle_input_src, handle_input_trg):

            src_line = undo_pieces(src_line)
            trg_line = undo_pieces(trg_line)

            json_dict = {"translation": {}}

            json_dict["translation"][args.src_lang] = src_line
            json_dict["translation"][args.trg_lang] = trg_line

            handle_output.write(json.dumps(json_dict, ensure_ascii=False, indent=None) + "\n")


if __name__ == "__main__":
    main()
