#! /usr/bin/python3

import re
import argparse
import logging
import json


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", type=str, help="Input file", required=True)
    parser.add_argument("--output-file", type=str, help="Output file", required=True)

    parser.add_argument("--key", type=str, help="Key to extract", required=True)

    parser.add_argument("--use-mouthing-tier", action="store_true",
                        help="Add mouthing tokens to gloss line for dgs_de only", required=False, default=False)

    args = parser.parse_args()

    return args


def sanitize_mouthing_line(input_string: str) -> str:
    """
    Remove content in curly brackets that was added by annotator, but was not visible
    in the video.

    :param input_string:
    :return:
    """
    input_string = re.sub(r"{.*?}", "", input_string)

    # remove mouth gestures that are too generic to be useful

    input_string = input_string.replace("[MG]", "")

    return " ".join(input_string.split())


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

            if args.use_mouthing_tier and args.key == "dgs_de":

                # add mouthing tokens with separator

                mouthing_line = data["mouthing"].strip()
                mouthing_line = sanitize_mouthing_line(mouthing_line)

                extracted_string += " +++"

                if len(mouthing_line) > 0:
                    extracted_string += " " + mouthing_line

            handle_output.write(extracted_string + "\n")


if __name__ == "__main__":
    main()
