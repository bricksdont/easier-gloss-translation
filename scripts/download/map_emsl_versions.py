#! /bin/python3

import sys

mapping = {
    "bsl": "EMSL_v2_based_on_EMSL_v1_BSL-I3D",
    "dgs": "EMSL_v2_based_on_EMSL_v1_DGS-I3D",
    "both": "EMSL_v2_based_on_EMSL_v1_Both-I3D",
    "0.5": "confidence_over_0.5",
    "0.6": "confidence_over_0.6",
    "0.7": "confidence_over_0.7",
    "0.8": "confidence_over_0.8"
}

input_string = sys.argv[1].strip()

sys.stdout.write(mapping[input_string])
