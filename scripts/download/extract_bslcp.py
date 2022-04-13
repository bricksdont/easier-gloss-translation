#! /usr/bin/python3

import re
import json
import logging
import argparse

import tensorflow as tf
import tensorflow_datasets as tfds

# noinspection PyUnresolvedReferences
from sign_language_datasets import datasets
from sign_language_datasets.datasets.config import SignDatasetConfig

from sign_language_datasets.datasets.bsl_corpus.bsl_corpus_utils import get_elan_sentences_bsl_corpus

from typing import List
from itertools import groupby


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--tfds-data-dir", type=str, help="Path to where a tfds data set should be saved.")
    parser.add_argument("--bslcp-username", type=str, help="Username for BSl corpus.")
    parser.add_argument("--bslcp-password", type=str, help="Password for BSl corpus.")
    parser.add_argument("--output-file", type=str, help="Path to file to write extracted sentences.")

    args = parser.parse_args()

    return args


def load(data_dir: str, bslcp_username: str, bslcp_password: str) -> tf.data.Dataset:
    """

    :param data_dir:
    :param bslcp_username:
    :param bslcp_password:
    :return:
    """
    config = SignDatasetConfig(name="only-annotations", version="1.0.0", include_video=False, include_pose=None)

    bslcp = tfds.load(name='bsl_corpus',
                      builder_kwargs={"config": config,
                                      "bslcp_username": bslcp_username,
                                      "bslcp_password": bslcp_password},
                      data_dir=data_dir)

    return bslcp


def remove_adjacent_duplicates(my_list: List[str]) -> List[str]:
    """

    :param my_list:
    :return:
    """
    return list(i for i, x in groupby(my_list))


def remove_signbank_comment(gloss: str) -> str:
    """

    :param gloss:
    :return:
    """
    if "ADD-TO-SIGNBANK" in gloss:
        print(gloss)
        return re.search(r"ADD-TO-SIGNBANK\((.+)\)", gloss).groups()[0]
    else:
        return gloss


def fix_glosses(glosses: List[str]) -> List[str]:
    """

    :param glosses:
    :return:
    """
    glosses = [remove_signbank_comment(g) for g in glosses]

    return remove_adjacent_duplicates(glosses)


def load_and_extract(data_dir: str, bslcp_username: str, bslcp_password: str, outfile_path: str):
    """

    :param data_dir:
    :param bslcp_username:
    :param bslcp_password:
    :param outfile_path:
    :return:
    """

    dataset = load(data_dir=data_dir, bslcp_username=bslcp_username, bslcp_password=bslcp_password)

    outfile_handle = open(outfile_path, "w")

    num_lines_seen = 0

    for datum in dataset["train"]:
        _id = datum["id"].numpy().decode('utf-8')

        elan_paths = datum["paths"]["eaf"]
        elan_paths = [e.numpy().decode('utf-8') for e in elan_paths]

        for elan_path in elan_paths:
            sentences = get_elan_sentences_bsl_corpus(elan_path)

            for sentence in sentences:
                # structure of sentence:
                # {'start': 354148,
                #  'end': 356223,
                #  'english': 'All Saints.',
                #  'glosses': [{'start': 355010, 'end': 356181, 'gloss': 'FS:SAINT ', 'hand': 'R'},
                #              {'start': 355010, 'end': 356181, 'gloss': 'FS:SAINT ', 'hand': 'L'}]
                #  }

                sentence_en = sentence["english"]

                glosses = []

                for gloss_dict in sentence["glosses"]:
                    gloss = gloss_dict["gloss"].strip()
                    glosses.append(gloss)

                # clean up known issues
                glosses = fix_glosses(glosses)

                sentence_bsl = " ".join(glosses)

                output_data = {"sentence_bsl": sentence_bsl,
                               "sentence_en": sentence_en,
                               "id": _id}

                outfile_handle.write(json.dumps(output_data) + "\n")

                num_lines_seen += 1

    logging.debug("Saw %d lines." % num_lines_seen)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    load_and_extract(data_dir=args.tfds_data_dir,
                     bslcp_username=args.bslcp_username,
                     bslcp_password=args.bslcp_password,
                     outfile_path=args.output_file)


if __name__ == '__main__':
    main()
