#! /usr/bin/python3

import sys

SOURCES = ["uhh", "bslcp"]
LANGUAGES = ["de", "en", "bsl", "dgs_de", "dgs_en"]


def chunks(lst, n):
    """
    Yield successive n-sized chunks from lst.

    https://stackoverflow.com/questions/312443/how-do-you-split-a-list-into-evenly-sized-chunks
    """
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


input_string = sys.stdin.read().strip()

print("#! /bin/bash")
print()
print("language_pairs=(")

parts = input_string.split(" ")

if len(parts) % 3 != 0:
    sys.stderr.write("ERROR: Language pairs array is not well-formed: %s" % str(parts) + "\n")
    sys.exit(1)

for source, src, trg in chunks(parts, n=3):

    if source not in SOURCES:
        sys.stderr.write("ERROR: Source '%s' not in known sources: '%s'" % (source, str(SOURCES)) + "\n")
        sys.exit(1)

    if src not in LANGUAGES:
        sys.stderr.write("ERROR: src '%s' not in known languages: '%s'" % (src, str(LANGUAGES)) + "\n")
        sys.exit(1)

    if trg not in LANGUAGES:
        sys.stderr.write("ERROR: trg '%s' not in known languages: '%s'" % (trg, str(LANGUAGES)) + "\n")
        sys.exit(1)

    print("    ", end="")
    print('"%s %s %s"' % (source, src, trg))
    pass

print(")")
print()
