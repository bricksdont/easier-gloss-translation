#! /usr/bin/python3

import random
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--seed", type=int, required=True,
                        help="Random seed.")
    parser.add_argument("--input", type=str, required=True,
                        help="Input file.")

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    random.seed(args.seed)

    lines = open(args.input).readlines()

    random.shuffle(lines)

    for line in lines:
        print(line, end="")

if __name__ == '__main__':
    main()