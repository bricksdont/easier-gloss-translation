#! /usr/bin/python3

import re
import argparse
import logging

DGS_GLOSS_SUFFIXES = ['dgs_de', 'dgs_en']
GLOSS_SUFFIXES = DGS_GLOSS_SUFFIXES + ['bsl', 'pan']
SPOKEN_SUFFIXES = ['de', 'en']
ALL_SUFFIXES = GLOSS_SUFFIXES + SPOKEN_SUFFIXES


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", type=str, help="Input file", required=True)
    parser.add_argument("--output-file", type=str, help="Output file", required=True)

    parser.add_argument("--lang", type=str, help="Language suffix", required=True, choices=ALL_SUFFIXES)

    parser.add_argument("--lowercase-glosses", type=str, choices=["true", "false"],
                        help="Lowercase if inputs are glosses", required=True)
    parser.add_argument("-generalize-dgs-glosses", type=str, choices=["true", "false"],
                        help="Generalize only if inputs are DGS glosses", required=True)

    args = parser.parse_args()

    return args


def generalize_pan_glosses(line: str) -> str:
    """
    Removes certain kinds of variation in order to bolster generalization.

    :param line:
    :return:
    """
    # remove ad-hoc deviations from citation forms
    line = line.replace("*", "")

    # remove distinction between type glosses and subtype glosses
    line = line.replace("^", "")

    # separate "||" concatenations
    line = line.replace("||", " ")

    # collapse phonological variations of the same type,
    # for number signs remove handshape variants

    glosses = line.split(" ")

    collapsed_glosses = []

    for gloss in glosses:

        if gloss in [".", "?", "!"]:
            collapsed_gloss = gloss
        else:
            collapsed_gloss_groups = re.search(r"([/$A-Z-ÖÄÜ]+[0-9]*)[A-Z]*", gloss).groups()
            collapsed_gloss = "".join([g for g in collapsed_gloss_groups if g is not None])
        collapsed_glosses.append(collapsed_gloss)

    line = " ".join(collapsed_glosses)

    return line


def generalize_dgs_glosses(line: str) -> str:
    """
    Removes certain kinds of variation in order to bolster generalization.

    Example:

    ICH1 ETWAS-PLANEN-UND-UMSETZEN1 SELBST1A* KLAPPT1* $GEST-OFF^ BIS-JETZT1 GEWOHNHEIT1* $GEST-OFF^*

    becomes:

    ICH1 ETWAS-PLANEN-UND-UMSETZEN1 SELBST1 KLAPPT1 $GEST-OFF BIS-JETZT1 GEWOHNHEIT1 $GEST-OFF

    :param line:
    :return:
    """
    # remove ad-hoc deviations from citation forms
    line = line.replace("*", "")

    # remove distinction between type glosses and subtype glosses
    line = line.replace("^", "")

    # collapse phonological variations of the same type,
    # for number signs remove handshape variants

    glosses = line.split(" ")

    collapsed_glosses = []

    for gloss in glosses:
        collapsed_gloss_groups = re.search(r"([$A-Z-ÖÄÜ]+[0-9]*)[A-Z]*", gloss).groups()
        collapsed_gloss = "".join([g for g in collapsed_gloss_groups if g is not None])
        collapsed_glosses.append(collapsed_gloss)

    line = " ".join(collapsed_glosses)

    return line


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    args.lowercase_glosses = bool(args.lowercase_glosses)
    args.generalize_dgs_glosses = bool(args.generalize_dgs_glosses)

    with open(args.input_file, "r") as handle_input, open(args.output_file, "w") as handle_output:

        for line in handle_input:
            line = line.strip()
            if args.lang in SPOKEN_SUFFIXES:
                # do nothing
                handle_output.write(line + "\n")
            else:
                # preprocess glosses
                if args.lowercase_glosses:
                    line = line.lower()

                if args.generalize_dgs_glosses and args.lang in DGS_GLOSS_SUFFIXES:
                    line = generalize_dgs_glosses(line)

                if args.generalize_dgs_glosses and args.lang == "pan":
                    line = generalize_pan_glosses(line)

                handle_output.write(line + "\n")


if __name__ == "__main__":
    main()
