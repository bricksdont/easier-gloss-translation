# based on: https://github.com/J22Melody/signwriting-translation/blob/main/app.py
# written by Zifan Jiang

import subprocess
import torch as pt
from os import environ
from flask import Flask, request
from flask_cors import CORS
from typing import List

from sockeye import inference, model

MODEL_PATH = './models'

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

model_name = 'dgs_de'
model_path = '{}/{}'.format(MODEL_PATH, model_name)

spm_name = "sentencepiece.model"
spm_path = './{}/{}'.format(model_path, spm_name)

device = pt.device('cpu')

sockeye_models, sockeye_source_vocabs, sockeye_target_vocabs = model.load_models(
    device=device, dtype=None, model_folders=[model_path], inference_only=True)


def remove_pieces(translation: str) -> str:
    """

    :param translation:
    :return:
    """
    translation = translation.replace(" ", "")
    translation = translation.replace("▁", " ")

    return translation


@app.route('/api/translate/<direction>', methods=['POST'])
def translate():
    payload = request.get_json()
    source_language_code = payload.get('source_language_code', 'de')
    target_language_code = payload.get('target_language_code', 'dgs')
    text = payload.get('text', '')

    n_best = int(payload.get('n_best', '3'))
    beam_size = n_best

    tag_str = '<2{}>'.format(target_language_code)
    command = 'echo "{} {}" | spm_encode --model={}'.format(tag_str, text, spm_path)
    input_ = subprocess.run(command, shell=True, check=True, capture_output=True)
    input_ = input_.stdout.decode("utf-8")

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
