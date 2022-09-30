#! /usr/bin/python3

import json
import logging
import argparse

from typing import Dict, Any, List


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--train", type=str, help="Path to local JSON file.", required=True)
    parser.add_argument("--dev", type=str, help="Path to local JSON file.", required=True)
    parser.add_argument("--test", type=str, help="Path to local JSON file.", required=True)

    args = parser.parse_args()

    return args


def load_json(filepath: str) -> List[Dict[str, Any]]:
    """

    :param filepath:
    :return:
    """
    entries = []  # type: List[Dict[str, Any]]

    with open(filepath, "r") as handle_input:

        for line in handle_input:
            entry = json.loads(line)
            entries.append(entry)

    return entries

# {"train":
#       {"document_id": ["sentence_id", ...],
#        ...
#       }
# }


OutputDict = Dict[str, Dict[str, List[str]]]


def add_to_output_dict(current_output_dict: OutputDict, data_to_add: List[Dict[str, Any]], top_level_key: str) -> OutputDict:
    """

    :param current_output_dict:
    :param data_to_add:
    :param top_level_key:
    :return:
    """
    assert top_level_key in current_output_dict.keys()

    for entry in data_to_add:
        document_id = entry["document_id"]
        sentence_id = entry["sentence_id"]

        if document_id not in current_output_dict[top_level_key].keys():
            current_output_dict[top_level_key][document_id] = []

        current_output_dict[top_level_key][document_id].append(sentence_id)

    return current_output_dict


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    train_data = load_json(args.train)
    dev_data = load_json(args.dev)
    test_data = load_json(args.test)

    output_dict = {"train": {}, "dev": {}, "test": {}}

    output_dict = add_to_output_dict(current_output_dict=output_dict, data_to_add=train_data, top_level_key="train")
    output_dict = add_to_output_dict(current_output_dict=output_dict, data_to_add=dev_data, top_level_key="dev")
    output_dict = add_to_output_dict(current_output_dict=output_dict, data_to_add=test_data, top_level_key="test")

    print(json.dumps(output_dict, indent=4))


if __name__ == '__main__':
    main()
