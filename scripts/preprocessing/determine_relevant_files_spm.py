#! /usr/bin/python3

import argparse
import logging

from typing import Iterator


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--langpairs", type=str, help="Language pairs", required=True)
    parser.add_argument("--spm-strategy", type=str, help="Output file", required=True)

    args = parser.parse_args()

    return args


def chunks(lst: list, n: int = 3):
    """
    Yield successive n-sized chunks from lst.

    https://stackoverflow.com/questions/312443/how-do-you-split-a-list-into-evenly-sized-chunks
    """
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def construct_filename(source: str, lang: str) -> str:
    """

    :param source:
    :param src:
    :param trg:
    :return:
    """
    return ".".join([source, "train", "normalized", lang])


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    relevant_files = []

    for source, src, trg in chunks(args.langpairs):

        if args.spm_strategy == "join":
            # if joint spm, collect all files
            relevant_file = ".".join()




if __name__ == "__main__":
    main()
