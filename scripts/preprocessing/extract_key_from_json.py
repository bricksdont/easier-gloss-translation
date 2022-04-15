#! /usr/bin/python3

import argparse
import logging
import json


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", type=str, help="Input file", required=True)
    parser.add_argument("--output-file", type=str, help="Output file", required=True)

    parser.add_argument("--key", type=str, help="Key to extract", required=True)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    with open(args.input_file, "r") as handle_input, open(args.output_file, "w") as handle_output:

        for line in handle_input:
            data = json.loads(line)

            if args.key == "pan":
                # then value is a dict, if it exists at all
                try:
                    extracted_string = data[args.key]["pan"].strip()
                except TypeError:
                    # PAN glosses do not exist
                    extracted_string = ""
            else:
                extracted_string = data[args.key].strip()
            handle_output.write(extracted_string + "\n")


if __name__ == "__main__":
    main()
