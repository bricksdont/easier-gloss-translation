#! /usr/bin/python3

import os
import logging
import argparse

import tensorflow as tf

import tensorflow_datasets as tfds

# noinspection PyUnresolvedReferences
from sign_language_datasets import datasets
from sign_language_datasets.datasets.config import SignDatasetConfig

from sign_language_datasets.datasets.bsl_corpus.bsl_corpus_utils import get_elan_sentences_bsl_corpus


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--tfds-data-dir", type=str, help="Path to where a tfds data set should be saved.")
    parser.add_argument("--bslcp-username", type=str, help="Username for BSl corpus.")
    parser.add_argument("--bslcp-password", type=str, help="Password for BSl corpus.")
    parser.add_argument("--output-folder", type=str, help="Path of folder to write extracted sentences.")

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


def load_and_extract(data_dir: str, bslcp_username: str, bslcp_password: str, output_folder: str):
    """

    :param data_dir:
    :param bslcp_username:
    :param bslcp_password:
    :param output_folder:
    :return:
    """

    dataset = load(data_dir=data_dir, bslcp_username=bslcp_username, bslcp_password=bslcp_password)

    outfile_path_en = os.path.join(output_folder, "bslcp.en")
    outfile_path_bsl = os.path.join(output_folder, "bslcp.bsl")

    outfile_handle_en = open(outfile_path_en, "w")
    outfile_handle_bsl = open(outfile_path_bsl, "w")

    num_lines_seen = 0

    for datum in dataset:

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

                sentence_bsl = " ".join(glosses)

                outfile_handle_en.write(sentence_en + "\n")
                outfile_handle_bsl.write(sentence_bsl + "\n")

                num_lines_seen += 1

    logging.debug("Saw %d lines." % num_lines_seen)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    load_and_extract(data_dir=args.tfds_data_dir,
                     bslcp_username=args.bslcp_username,
                     bslcp_password=args.bslcp_password,
                     output_folder=args.output_folder)


if __name__ == '__main__':
    main()
