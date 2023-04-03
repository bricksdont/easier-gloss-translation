# based on: https://github.com/J22Melody/signwriting-translation/blob/main/app.py
# written by Zifan Jiang

import os
import subprocess
import torch as pt
from os import environ
from flask import Flask, request
from flask_cors import CORS
from typing import List

from sockeye import inference, model

MODELS_PATH = './models'

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# load Sockeye models ahead of time, before a request comes in


def load_sockeye_models():

    model_name = 'dgs_de'
    spm_name = "sentencepiece.model"

    sockeye_paths_dict = {
        "nmt-basic": {"model_name": 'dgs_de_basic',
                      "model_path": os.path.join(MODELS_PATH, model_name),
                      "spm_path": os.path.join(MODELS_PATH, model_name, spm_name)
                      },
        "nmt-augmented": {"model_name": 'dgs_de_augmented',
                          "model_path": os.path.join(MODELS_PATH, model_name),
                          "spm_path": os.path.join(MODELS_PATH, model_name, spm_name)
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


def remove_pieces(translation: str) -> str:
    """

    :param translation:
    :return:
    """
    translation = translation.replace(" ", "")
    translation = translation.replace("▁", " ")

    return translation.strip()


@app.route('/api/translate/reorder', methods=['POST'], strict_slashes=False)
def translate():
    return {
        'works': 'yes! I think I am the reordering system'
    }


@app.route('/api/translate/nmt-augmented', methods=['POST'], strict_slashes=False)
def translate():
    return {
        'works': 'yes! I think I am the NMT augmented system'
    }


@app.route('/api/translate/nmt-basic', methods=['POST'], strict_slashes=False)
def translate():
    model_name = "nmt-basic"

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
    output = translator.translate([input_])[0]

    translations = output.nbest_translations  # type: List[str]
    translations = [remove_pieces(t) for t in translations]

    return {
        'source_language_code': source_language_code,
        'target_language_code': target_language_code,
        'n_best': n_best,
        'text': text,
        'translations': translations,
    }


if __name__ == '__main__':
    port = int(environ.get('PORT', 3030))
    with app.app_context():
        app.run(threaded=False,
                debug=False,
                port=port)
