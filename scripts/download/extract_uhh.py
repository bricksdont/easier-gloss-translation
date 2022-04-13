#! /usr/bin/python3

import re
import json
import logging
import argparse

from typing import Dict, Tuple

import tensorflow_datasets as tfds

# noinspection PyUnresolvedReferences
from sign_language_datasets import datasets
from sign_language_datasets.datasets.config import SignDatasetConfig

from sign_language_datasets.datasets.dgs_corpus.dgs_utils import get_elan_sentences


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--pan-json", type=str, help="Path to local JSON file.")
    parser.add_argument("--output-file", type=str, help="Path to file to write extracted sentences.")
    parser.add_argument("--tfds-data-dir", type=str, help="Path to where a tfds data set should be saved.")

    args = parser.parse_args()

    return args


def get_id_miliseconds_from_url(url: str) -> Tuple[str, int]:
    """
    Example: “https://www.sign-lang.uni-hamburg.de/meinedgs/html/1176340_de.html#t00000000”

    :param url:
    :return:
    """
    parts = url.split("/")[-1].split("#")

    _id = parts[0].replace("_de.html", "")
    start_time_string = parts[1][1:]

    # time format is:
    # t54361926 -> 54 hours, 36 minutes, 19 seconds, 26 frames (50 fps, each frame is 20 miliseconds)
    string_chunks = re.findall('..', start_time_string)
    hours, minutes, seconds, frames = [int(s) for s in string_chunks]

    start_time_miliseconds = frames * 20
    start_time_miliseconds += seconds * 1000
    start_time_miliseconds += minutes * 1000 * 60
    start_time_miliseconds += hours * 1000 * 60 * 60

    return _id, start_time_miliseconds


def extract_pan_data(json_path: str) -> Dict:
    """

    :param json_path:
    :return:
    """

    extracted_data = {}

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
        _id, start_time_miliseconds = get_id_miliseconds_from_url(entry["url"])

        if _id not in extracted_data.keys():
            extracted_data[_id] = {}

        start_frame = miliseconds_to_frame_index(start_time_miliseconds)

        extracted_data[_id][start_frame] = entry

    return extracted_data


def miliseconds_to_frame_index(ms: int, fps: int = 50) -> int:
    """
    :param ms:
    :param fps:
    :return:
    """
    return int(fps * (ms / 1000))


def extract_and_write(json_path: str,
                      outfile_path: str,
                      tfds_data_dir: str) -> None:
    """

    :param json_path:
    :param outfile_path:
    :param tfds_data_dir:
    :return:
    """
    outfile_handle = open(outfile_path, "w")

    fps = 50

    config = SignDatasetConfig(name="only-annotations", version="1.0.0", include_video=False, include_pose=None)
    dgs_corpus = tfds.load('dgs_corpus', builder_kwargs=dict(config=config), data_dir=tfds_data_dir)

    pan_data = extract_pan_data(json_path=json_path)

    pan_stats = {"found": 0, "missing (expected)": 0, "missing (unexpected)": 0}

    for datum in dgs_corpus["train"]:
        _id = datum["id"].numpy().decode('utf-8')

        elan_path = datum["paths"]["eaf"].numpy().decode('utf-8')
        sentences = get_elan_sentences(elan_path)

        for sentence in sentences:
            participant = sentence["participant"].lower()
            glosses = sentence["glosses"]

            if len(glosses) == 0:
                continue

            # relevant keys: EN: 'Sign' and DE: 'gloss'
            gloss_line_german = " ".join([g["gloss"] for g in glosses])
            gloss_line_english = " ".join([g["Sign"] for g in glosses])

            line_german = sentence["german"]
            line_english = sentence["english"] if sentence["english"] is not None else ""

            # get timing information for sentence
            start_frame = miliseconds_to_frame_index(sentence["start"], fps)
            end_frame = miliseconds_to_frame_index(sentence["end"], fps)

            # look for entry in pan data that corresponds

            pan_data_for_id = pan_data[_id]

            if start_frame in pan_data_for_id.keys():
                gloss_line_pan = pan_data[_id][start_frame]

                pan_stats["found"] += 1
            elif line_german.endswith("/"):
                # unfinished sentences that Thomas excluded from PAN
                # Example: "Ich hatte mein Flugticket/" in
                # https://www.sign-lang.uni-hamburg.de/meinedgs/html/1429910-16075041-16115817_de.html
                gloss_line_pan = ""
                pan_stats["missing (expected)"] += 1
            else:
                logging.warning("PAN entry missing unexpectedly for start frame '%d', id: '%s', line_german: '%s'",
                                start_frame, _id, line_german)
                gloss_line_pan = ""
                pan_stats["missing (unexpected)"] += 1

            output_data = {"dgs_de": gloss_line_german,
                           "dgs_en": gloss_line_english,
                           "de": line_german,
                           "en": line_english,
                           "start_frame": start_frame,
                           "end_frame": end_frame,
                           "participant": participant,
                           "pan": gloss_line_pan,
                           "id": _id}

            outfile_handle.write(json.dumps(output_data) + "\n")

    logging.debug("Pan stats: %s", pan_stats)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    extract_and_write(json_path=args.pan_json, outfile_path=args.output_file, tfds_data_dir=args.tfds_data_dir)


if __name__ == '__main__':
    main()
