# ! /usr/bin/python3

import argparse
import logging
import string

from typing import List

SPOKEN_SUFFIXES = ['de', 'en']


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-src", type=str, help="Source input file", required=True)
    parser.add_argument("--input-trg", type=str, help="Target input file", required=True)

    parser.add_argument("--output-src", type=str, help="Source output file", required=True)
    parser.add_argument("--output-trg", type=str, help="Target output file", required=True)

    parser.add_argument("--src-lang", type=str, help="Source language", required=True)
    parser.add_argument("--trg-lang", type=str, help="Target language", required=True)

    args = parser.parse_args()

    return args


string_table = str.maketrans(dict.fromkeys(string.punctuation))


def remove_punctuation(input_sentence: str) -> str:
    """

    :param input_sentence:
    :return:
    """
    return input_sentence.translate(string_table)


def get_variants(input_sentence: str) -> List[str]:
    """

    :param input_sentence:
    :return:
    """

    variants = [input_sentence]

    # lowercase

    variants += input_sentence.lower()

    # titlecase

    variants += input_sentence.title()

    # uppercase

    variants += input_sentence.upper()

    # punctuation symbols removed

    variants += remove_punctuation(input_sentence)

    # punctuation symbols removed and lowercase

    variants += remove_punctuation(input_sentence.lower())

    assert len(variants) == 6, "Length of variants is not 6: %s" % (str(variants))

    return variants


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    num_input_lines = 0
    num_output_lines = 0

    with open(args.input_src, "r") as handle_input_src, \
            open(args.input_trg, "r") as handle_input_trg, \
            open(args.output_src, "w") as handle_output_src, \
            open(args.output_trg, "w") as handle_output_trg:

        for src_line, trg_line in zip(handle_input_src, handle_input_trg):

            num_input_lines += 1

            if args.src_lang in SPOKEN_SUFFIXES:
                src_variants = get_variants(src_line.strip())
                trg_variants = [src_line.strip()] * len(src_variants)
            elif args.trg_lang in SPOKEN_SUFFIXES:
                trg_variants = get_variants(src_line.strip())
                src_variants = [src_line.strip()] * len(trg_variants)
            else:
                raise NotImplementedError("Don't know what to do without a spoken language suffix.")

            num_output_lines += len(src_variants)

            for src_variant, trg_variant in zip(src_variants, trg_variants):
                handle_output_src.write(src_variant + "\n")
                handle_output_trg.write(trg_variant + "\n")

    logging.debug("Seen %d input lines, resulted in %d output lines." % (num_input_lines, num_output_lines))


if __name__ == "__main__":
    main()
