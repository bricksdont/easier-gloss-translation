# based on: https://github.com/J22Melody/signwriting-translation/blob/main/app.py
# originally written by Zifan Jiang

import os

import sockeye.inference
import spacy
import subprocess
import torch as pt

from os import environ
from flask import Flask, request
from flask_cors import CORS
from typing import List, Dict, Any

from sockeye import inference, model

# local import

from reordering import text_to_gloss

MODELS_PATH = './models'

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# load Sockeye models ahead of time, before a request comes in


def load_sockeye_models():

    spm_name = "sentencepiece.model"

    sockeye_paths_dict = {
        "nmt_basic": {
                      "model_path": os.path.join(MODELS_PATH, "dgs_de"),
                      "spm_path": os.path.join(MODELS_PATH, "dgs_de", spm_name)
                      },
        "nmt_augmented": {
                          "model_path": os.path.join(MODELS_PATH, "dgs_de_augmented"),
                          "spm_path": os.path.join(MODELS_PATH, "dgs_de_augmented", spm_name)
                          }
    }

    sockeye_models_dict = {}

    device = pt.device('cpu')

    for model_name in sockeye_paths_dict.keys():

        sockeye_paths = sockeye_paths_dict[model_name]
        model_path = sockeye_paths["model_path"]

        sockeye_models, sockeye_source_vocabs, sockeye_target_vocabs = model.load_models(
            device=device, dtype=None, model_folders=[model_path], inference_only=True)

        sockeye_models_dict[model_name] = {"sockeye_models": sockeye_models,
                                           "sockeye_source_vocabs": sockeye_source_vocabs,
                                           "sockeye_target_vocabs": sockeye_target_vocabs}

    return device, sockeye_paths_dict, sockeye_models_dict


device, sockeye_paths_dict, sockeye_models_dict = load_sockeye_models()


def load_spacy_models():

    spacy_models = {
        "de": spacy.load("de_core_news_lg"),
        "fr": spacy.load("fr_core_news_lg")
    }

    return spacy_models


spacy_models = load_spacy_models()


def remove_pieces(translation: str) -> str:
    """

    :param translation:
    :return:
    """
    translation = translation.replace(" ", "")
    translation = translation.replace("▁", " ")

    return translation.strip()


@app.route('/api/translate/reorder', methods=['POST'], strict_slashes=False)
def reorder():

    payload = request.get_json()
    source_language_code = payload.get('source_language_code', 'de')
    target_language_code = payload.get('target_language_code', 'dgs')
    text = payload.get('text', '')

    spacy_model = spacy_models[source_language_code]

    translations = [text_to_gloss(text, spacy_model=spacy_model, lang=source_language_code)]

    return {
        'source_language_code': source_language_code,
        'target_language_code': target_language_code,
        'text': text,
        'n_best': -1,
        'translations': translations,
    }


def translate_model_agnostic(model_name: str) -> Dict[str, Any]:
    """

    :param model_name:
    :return:
    """
    spm_path = sockeye_paths_dict[model_name]["spm_path"]

    sockeye_models = sockeye_models_dict[model_name]["sockeye_models"]
    sockeye_source_vocabs = sockeye_models_dict[model_name]["sockeye_source_vocabs"]
    sockeye_target_vocabs = sockeye_models_dict[model_name]["sockeye_target_vocabs"]

    payload = request.get_json()
    source_language_code = payload.get('source_language_code', 'de')
    target_language_code = payload.get('target_language_code', 'dgs')
    text = payload.get('text', '')

    n_best = int(payload.get('n_best', '3'))
    beam_size = n_best

    tag_str = '<2{}>'.format(target_language_code)
    command = 'echo "{}" | spm_encode --model={}'.format(text, spm_path)
    input_ = subprocess.run(command, shell=True, check=True, capture_output=True)
    input_ = input_.stdout.decode("utf-8")
    input_ = tag_str + " " + input_

    translator = inference.Translator(device=device,
                                      ensemble_mode='linear',
                                      scorer=inference.CandidateScorer(),
                                      output_scores=True,
                                      batch_size=1,
                                      beam_size=beam_size,
                                      beam_search_stop='all',
                                      nbest_size=n_best,
                                      models=sockeye_models,
                                      source_vocabs=sockeye_source_vocabs,
                                      target_vocabs=sockeye_target_vocabs)

    input_ = inference.make_input_from_plain_string(0, input_)
    output = translator.translate([input_])[0]  # type: sockeye.inference.TranslatorOutput

    translations = output.nbest_translations  # type: List[str]
    translations = [remove_pieces(t) for t in translations]

    return {
        'source_language_code': source_language_code,
        'target_language_code': target_language_code,
        'n_best': n_best,
        'text': text,
        'translations': translations,
    }


@app.route('/api/translate/nmt-augmented', methods=['POST'], strict_slashes=False)
def translate_augmented() -> Dict[str, Any]:
    """

    :return:
    """
    return translate_model_agnostic(model_name="nmt_augmented")


@app.route('/api/translate/nmt-basic', methods=['POST'], strict_slashes=False)
def translate_basic() -> Dict[str, Any]:
    """

    :return:
    """
    return translate_model_agnostic(model_name="nmt_basic")


if __name__ == '__main__':
    port = int(environ.get('PORT', 3030))
    with app.app_context():
        app.run(threaded=False,
                debug=False,
                port=port)
