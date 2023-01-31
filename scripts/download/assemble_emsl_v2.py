#! /usr/bin/python3

import os
import csv
import srt
import json
import logging
import argparse

from typing import List, Dict


BOILERPLATE_SUBTITLES = ["1:1-Untertitelung.",
                         "Livepassagen können Fehler enthalten."]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--emsl-dir", type=str, help="Path to EMSL spots (with subfolders 'train', 'dev' and 'test').")

    parser.add_argument("--subtitles-dir-train", type=str, help="Path to SRF train subtitles folder.")
    parser.add_argument("--subtitles-dir-dev", type=str, help="Path to SRF dev subtitles folder.")
    parser.add_argument("--subtitles-dir-test", type=str, help="Path to SRF test subtitles folder.")

    parser.add_argument("--output-dir", type=str, help="Path to folder to write extracted sentences (will write three"
                                                       "separate JSON files).")

    args = parser.parse_args()

    return args


def read_srt(filepath: str) -> List[srt.Subtitle]:
    """
    :param filepath:
    :return:
    """
    subtitles = []

    with open(filepath, "r") as handle:
        for subtitle in srt.parse(handle.read()):

            if subtitle.content.strip() in BOILERPLATE_SUBTITLES:
                continue
            elif subtitle.content.startswith("#"):
                continue

            elif subtitle.content.strip() == "":
                continue

            subtitles.append(subtitle)

    return subtitles


def load_emsl_file(filepath: str) -> List[str]:
    """
    Filename of the form: "2021-02-17.csv"

    File content is a CSV with a header, as follows:

    video_name|index|start_sec|end_sec|target
    2021-01-13|1|8.52|12.36|untertitel mein dame txt


    :param filepath:
    :return:
    """
    emsl_strings = []  # type: List[str]

    with open(filepath) as csvfile:
        reader = csv.DictReader(csvfile, delimiter="|")
        for row in reader:
            emsl_strings.append(row["target"])

    return emsl_strings


def get_emsl_strings_by_id(emsl_dir: str, subset_identifier: str) -> Dict[str, List[str]]:
    """

    :param emsl_dir:
    :param subset_identifier:
    :return:
    """
    emsl_dir_subset = os.path.join(emsl_dir, subset_identifier)

    emsl_strings_by_id = {}  # type: Dict[str, List[str]]

    for emsl_filename in os.listdir(emsl_dir_subset):
        filepath = os.path.join(emsl_dir_subset, emsl_filename)

        file_id = emsl_filename.replace(".csv", "")

        emsl_strings = load_emsl_file(filepath)

        emsl_strings_by_id[file_id] = emsl_strings

    return emsl_strings_by_id


def get_subtitles_by_id(subtitles_dir: str) -> Dict[str, List[srt.Subtitle]]:
    """
    Filename structure:
    - srf.2020-05-27.srt (for train)
    - dev.215.srt (for dev and test)

    :param subtitles_dir:
    :return:
    """
    subtitles_by_id = {}  # type: Dict[str, List[srt.Subtitle]]

    for subtitle_filename in os.listdir(subtitles_dir):
        filepath = os.path.join(subtitles_dir, subtitle_filename)

        file_id = subtitle_filename.replace(".srt", "").replace("srf.", "")

        subtitles = read_srt(filepath)

        subtitles_by_id[file_id] = subtitles

    return subtitles_by_id


def write_output(emsl_strings_by_id: Dict[str, List[str]],
                 subtitles_by_id: Dict[str, List[srt.Subtitle]],
                 output_dir: str,
                 subset_identifier: str):
    """

    :param emsl_strings_by_id:
    :param subtitles_by_id:
    :param output_dir:
    :param subset_identifier:
    :return:
    """
    outfile_path = os.path.join(output_dir, "%s.json" % subset_identifier)

    outfile_handle = open(outfile_path, "w")

    num_lines_seen = 0
    num_lines_skipped_because_empty = 0

    for file_id in sorted(emsl_strings_by_id.keys()):
        emsl_strings = emsl_strings_by_id[file_id]
        subtitles = subtitles_by_id[file_id]

        assert len(emsl_strings) == len(subtitles), "For file_id: %s number of EMSL spots (%d) and subtitles (%d) not " \
                                                    "equal." % (file_id, len(emsl_strings), len(subtitles))

        for sentence_index, (emsl_string, subtitle) in enumerate(zip(emsl_strings, subtitles)):
            subtitle_string = subtitle.content
            _id = file_id + "." + str(sentence_index)

            emsl_string = emsl_string.strip()
            subtitle_string = subtitle_string.strip()

            if emsl_string == "" or subtitle_string == "":
                num_lines_skipped_because_empty += 1
                continue

            output_data = {"dsgs": emsl_string,
                           "de": subtitle_string,
                           "id": _id}

            outfile_handle.write(json.dumps(output_data) + "\n")

            num_lines_seen += 1

    logging.debug("Skipped %d lines that have empty strings." % num_lines_skipped_because_empty)
    logging.debug("Wrote %d valid lines to %s." % (num_lines_seen, outfile_path))


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    # parse the train subset

    emsl_strings_by_id = get_emsl_strings_by_id(args.emsl_dir, subset_identifier="train")

    subtitles_by_id = get_subtitles_by_id(args.subtitles_dir_train)

    write_output(emsl_strings_by_id=emsl_strings_by_id,
                 subtitles_by_id=subtitles_by_id,
                 output_dir=args.output_dir,
                 subset_identifier="train")

    # dev

    emsl_strings_by_id = get_emsl_strings_by_id(args.emsl_dir, subset_identifier="dev")

    subtitles_by_id = get_subtitles_by_id(args.subtitles_dir_dev)

    write_output(emsl_strings_by_id=emsl_strings_by_id,
                 subtitles_by_id=subtitles_by_id,
                 output_dir=args.output_dir,
                 subset_identifier="dev")

    # test

    emsl_strings_by_id = get_emsl_strings_by_id(args.emsl_dir, subset_identifier="test")

    subtitles_by_id = get_subtitles_by_id(args.subtitles_dir_test)

    write_output(emsl_strings_by_id=emsl_strings_by_id,
                 subtitles_by_id=subtitles_by_id,
                 output_dir=args.output_dir,
                 subset_identifier="test")


if __name__ == '__main__':
    main()
