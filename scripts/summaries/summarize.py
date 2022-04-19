#! /usr/bin/python3

import os
import argparse
import logging
import itertools
import operator

from typing import List, Tuple


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--eval-folder", type=str, help="Path that should be searched for results.",
                        required=True)

    args = parser.parse_args()

    return args


def walklevel(some_dir, level=1):
    """
    Taken from:
    https://stackoverflow.com/a/234329/1987598
    :param some_dir:
    :param level:
    :return:
    """
    some_dir = some_dir.rstrip(os.path.sep)

    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        yield root, dirs, files
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]


def parse_filename(filename: str):
    """
    Structure:  $source.$corpus.$test_src-$test_trg.$metric
    Example:    bslcp.test.bsl-en.bleu

    :param filename:
    :return:
    """
    parts = filename.split(".")

    if len(parts) != 4:
        logging.error("Cannot parse filename: '%s'" % filename)

    source, corpus, langpair, metric = parts

    test_src, test_trg = langpair.split("-")

    return source, corpus, test_src, test_trg, metric


def read_bleu(filename: str) -> str:
    """

    :param filename:
    :return:
    """
    with open(filename, "r") as infile:
        line = infile.readline().strip()

        parts = line.split(" ")

    if len(parts) < 3:
        return "-"

    return parts[2]


def read_chrf(filename: str) -> str:
    """
    Example content: #chrF2+numchars.6+space.false+version.1.4.14 = 0.47
    :param filename:
    :return:
    """

    with open(filename, "r") as infile:
        line = infile.readline().strip()

        parts = line.split(" ")

    if len(parts) < 3:
        return "-"

    return parts[2]


def read_metric_values(metric: str, filepath: str):
    """

    :param metric:
    :param filepath:
    :return:
    """
    if metric == "bleu":
        metric_names = ["BLEU"]
        metric_values = [read_bleu(filepath)]
    elif metric == "chrf":
        metric_names = ["CHRF"]
        metric_values = [read_chrf(filepath)]
    else:
        raise NotImplementedError

    return metric_names, metric_values


def is_multilingual(langpair: str) -> bool:
    """

    :param langpair:
    :return:
    """
    return True


def parse_model_name(model_name: str) -> Tuple[str, str, str]:
    """
    Examples:

    lg.false+gdg.true+ss.joint
    lg.false+ss.spoken-only
    multilingual.true+lg.false+ss.spoken-only

    :param model_name:
    :return:
    """
    lowercase_glosses, generalize_dgs_glosses, spm_strategy = "-", "-", "-"

    pairs = model_name.split("+")

    for pair in pairs:
        key, value = pair.split(".")

        if key == "lg":
            lowercase_glosses = value
        elif key == "gdg":
            generalize_dgs_glosses = value
        elif key == "ss":
            spm_strategy = value
        elif key == "multilingual":
            continue
        else:
            logging.warning("Could not parse (key, value:): %s, %s", key, value)
            raise NotImplementedError

    return lowercase_glosses, generalize_dgs_glosses, spm_strategy


class Result(object):

    def __init__(self,
                 langpair,
                 model_name,
                 corpus,
                 source,
                 test_src,
                 test_trg,
                 lowercase_glosses,
                 generalize_dgs_glosses,
                 spm_strategy,
                 metric_names,
                 metric_values):
        self.langpair = langpair
        self.model_name = model_name
        self.corpus = corpus
        self.source = source
        self.test_src = test_src
        self.test_trg = test_trg
        self.lowercase_glosses = lowercase_glosses
        self.generalize_dgs_glosses = generalize_dgs_glosses
        self.spm_strategy = spm_strategy
        self.metric_dict = {}

        self.update_metrics(metric_names, metric_values)

    def update_metrics(self,
                       metric_names,
                       metric_values):
        for name, value in zip(metric_names, metric_values):
            self.update_metric(name, value)

    def update_metric(self, metric_name, metric_value):
        assert metric_name not in self.metric_dict.keys(), "Refusing to overwrite existing metric key!"
        self.metric_dict[metric_name] = metric_value

    def __repr__(self):
        metric_dict = str(self.metric_dict)

        return "Result(%s)" % "+".join([self.langpair,
                                        self.model_name,
                                        self.corpus,
                                        self.source,
                                        self.test_src,
                                        self.test_trg,
                                        self.lowercase_glosses,
                                        self.generalize_dgs_glosses,
                                        self.spm_strategy,
                                        metric_dict])

    def signature(self) -> str:
        return "+".join([self.langpair,
                         self.model_name,
                         self.corpus,
                         self.source,
                         self.test_src,
                         self.test_trg,
                         self.lowercase_glosses,
                         self.generalize_dgs_glosses,
                         self.spm_strategy])


def collapse_metrics(results: List[Result]) -> Result:
    """
    :param results:
    :return:
    """
    first_result = results[0]

    for r in results[1:]:
        for name, value in r.metric_dict.items():
            first_result.update_metric(name, value)

    return first_result


def reduce_results(results: List[Result]) -> List[Result]:
    """
    :param results:
    :return:
    """

    with_signatures = [(r.signature(), r) for r in results]  # type: List[Tuple[str, Result]]
    with_signatures.sort(key=operator.itemgetter(0))

    by_signature_iterator = itertools.groupby(with_signatures, operator.itemgetter(0))

    reduced_results = []

    for signature, subiterator in by_signature_iterator:
        subresults = [r for s, r in subiterator]
        reduced_result = collapse_metrics(subresults)
        reduced_results.append(reduced_result)

    return reduced_results


def get_subdirectories(eval_folder: str) -> List[str]:
    """

    :param eval_folder:
    :return:
    """

    langpairs = []

    for filename in os.listdir(eval_folder):
        filepath = os.path.join(eval_folder, filename)
        if os.path.isdir(filepath):
            langpairs.append(filepath)

    return langpairs


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    results = []

    langpairs = get_subdirectories(args.eval_folder)

    logging.debug("Language pairs:")
    logging.debug(langpairs)

    for langpair_index, langpair in enumerate(langpairs):

        path_langpair = os.path.join(args.eval_folder, langpair)

        model_names = get_subdirectories(path_langpair)

        if langpair_index == 0:
            logging.debug("Model names:")
            logging.debug(model_names)

        for model_name in model_names:
            path_model = os.path.join(path_langpair, model_name)

            lowercase_glosses, generalize_dgs_glosses, spm_strategy = parse_model_name(model_name)

            for _, _, files in os.walk(path_model):
                for file in files:
                    source, corpus, test_src, test_trg, metric = parse_filename(file)

                    filepath = os.path.join(path_model, file)

                    metric_names, metric_values = read_metric_values(metric, filepath)

                    result = Result(langpair,
                                    model_name,
                                    corpus,
                                    source,
                                    test_src,
                                    test_trg,
                                    lowercase_glosses,
                                    generalize_dgs_glosses,
                                    spm_strategy,
                                    metric_names,
                                    metric_values)

                    results.append(result)

    results = reduce_results(results)

    header_names = ["LANGPAIR",
                    "MODEL_NAME",
                    "CORPUS",
                    "SOURCE",
                    "TEST_SRC",
                    "TEST_TRG",
                    "LOWERCASE_GLOSSES",
                    "GENERALIZE_DGS_GLOSSES",
                    "SPM_STRATEGY"]

    metric_names = ["BLEU",
                    "CHRF"]

    print("\t".join(header_names))

    for r in results:
        values = [r.langpair, r.model_name, r.corpus, r.source, r.test_src, r.test_trg,
                  r.lowercase_glosses, r.generalize_dgs_glosses, r.spm_strategy]
        metrics = [r.metric_dict.get(m, "-") for m in metric_names]

        print("\t".join(values + metrics))


if __name__ == '__main__':
    main()
