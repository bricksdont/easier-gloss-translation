#! /usr/bin/python3

import re
import argparse
import logging

DGS_GLOSS_SUFFIXES = ['dgs_de', 'dgs_en']
GLOSS_SUFFIXES = DGS_GLOSS_SUFFIXES + ['bsl', 'pan']
SPOKEN_SUFFIXES = ['de', 'en']
ALL_SUFFIXES = GLOSS_SUFFIXES + SPOKEN_SUFFIXES

GLOSSES_TO_IGNORE = ["$GEST-OFF", "$$EXTRA-LING-MAN"]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", type=str, help="Input file", required=True)
    parser.add_argument("--output-file", type=str, help="Output file", required=True)

    parser.add_argument("--lang", type=str, help="Language suffix", required=True, choices=ALL_SUFFIXES)

    parser.add_argument("--lowercase-glosses", type=str, choices=["true", "false"],
                        help="Lowercase if inputs are glosses", required=True)
    parser.add_argument("--generalize-dgs-glosses", type=str, choices=["true", "false"],
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
            try:
                collapsed_gloss_groups = re.search(r"([/$A-Z-ÖÄÜ]+[0-9]*)[A-Z]*", gloss).groups()
                collapsed_gloss = "".join([g for g in collapsed_gloss_groups if g is not None])
            except AttributeError:
                logging.error("Gloss could not be generalized: '%s'", gloss)
                collapsed_gloss = gloss

        collapsed_glosses.append(collapsed_gloss)

    line = " ".join(collapsed_glosses)

    return line


def collapse_gloss(gloss: str) -> str:
    """
    Collapse phonological variations of the same type, and
    - for number signs remove handshape variants
    - keep numerals ($NUM), list glosses ($LIST) and finger alphabet ($ALPHA)

    :param gloss:
    :return:
    """
    try:
        collapsed_gloss_groups = re.search(r"([$A-Z-ÖÄÜ]+[0-9]*)[A-Z]*(:?[0-9A-ZÖÄÜ]*o?f?[0-9]*)", gloss).groups()
        collapsed_gloss = "".join([g for g in collapsed_gloss_groups if g is not None])
    except AttributeError:
        logging.error("Gloss could not be generalized: '%s'", gloss)
        collapsed_gloss = gloss

    return collapsed_gloss


def generalize_dgs_glosses(line: str) -> str:
    """
    Removes certain kinds of variation in order to bolster generalization.

    Example:

    ICH1 ETWAS-PLANEN-UND-UMSETZEN1 SELBST1A* KLAPPT1* $GEST-OFF^ BIS-JETZT1 GEWOHNHEIT1* $GEST-OFF^*

    becomes:

    ICH1 ETWAS-PLANEN-UND-UMSETZEN1 SELBST1 KLAPPT1 BIS-JETZT1 GEWOHNHEIT1

    :param line:
    :return:
    """
    # remove ad-hoc deviations from citation forms
    line = line.replace("*", "")

    # remove distinction between type glosses and subtype glosses
    line = line.replace("^", "")

    glosses = line.split(" ")

    collapsed_glosses = []

    for gloss in glosses:
        collapsed_gloss = collapse_gloss(gloss)

        # remove special glosses that cannot possibly help translation
        if collapsed_gloss in GLOSSES_TO_IGNORE:
            continue

        collapsed_glosses.append(collapsed_gloss)

    line = " ".join(collapsed_glosses)

    return line


def bool_from_string(bool_as_string: str) -> bool:
    """

    :param bool_as_string:
    :return:
    """
    if bool_as_string == "true":
        return True
    else:
        return False


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    args.lowercase_glosses = bool_from_string(args.lowercase_glosses)  # type: ignore
    args.generalize_dgs_glosses = bool_from_string(args.generalize_dgs_glosses)  # type: ignore

    with open(args.input_file, "r") as handle_input, open(args.output_file, "w") as handle_output:

        for line in handle_input:
            line = line.strip()
            if args.lang in SPOKEN_SUFFIXES:
                # do nothing
                handle_output.write(line + "\n")
            else:
                # preprocess glosses

                if args.generalize_dgs_glosses and args.lang in DGS_GLOSS_SUFFIXES:
                    line = generalize_dgs_glosses(line)

                if args.generalize_dgs_glosses and args.lang == "pan":
                    line = generalize_pan_glosses(line)

                if args.lowercase_glosses:
                    line = line.lower()

                handle_output.write(line + "\n")


if __name__ == "__main__":
    main()
