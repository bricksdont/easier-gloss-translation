#! /usr/bin/python3

import os
import json
import logging
import argparse

from typing import Iterator


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", type=str, help="Path to local JSON file.")
    parser.add_argument("--output-folder", type=str, help="Path of folder to write extracted sentences.")

    args = parser.parse_args()

    return args


def extract(json_path: str) -> Iterator:
    """

    :param json_path:
    :return:
    """
    with open(json_path) as infile:
        data = json.load(infile)

    # structure of entries:
    # [
    #   {
    #     "url": "https://www.sign-lang.uni-hamburg.de/meinedgs/html/1176340_de.html#t00000000",
    #     "spoken": "Sieh her, jetzt musst du meine Geschichte aus deinem Gedächtnis löschen.",
    #     "pan": "SEHEN-AUF1^ MUSS1 HIRN1A^ //LÖSCHEN1A MEIN1 GESCHICHTE2 ."
    #   }, ...
    # ]
    for entry in data:
        yield entry["spoken"], entry["pan"]


def extract_and_write(json_path: str, output_folder: str) -> None:
    """

    :param json_path:
    :param output_folder:
    :return:
    """
    outfile_path_de = os.path.join(output_folder, "data.de")
    outfile_path_dgs = os.path.join(output_folder, "data.dgs")

    outfile_handle_de = open(outfile_path_de, "w")
    outfile_handle_dgs = open(outfile_path_dgs, "w")

    num_lines_seen = 0

    for spoken_sentence, pan_sentence in extract(json_path=json_path):
        outfile_handle_de.write(spoken_sentence + "\n")
        outfile_handle_dgs.write(pan_sentence + "\n")

        num_lines_seen += 1

    logging.debug("Saw %d lines." % num_lines_seen)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    extract_and_write(json_path=args.input_file, output_folder=args.output_folder)


if __name__ == '__main__':
    main()
