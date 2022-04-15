#! /usr/bin/python3

import sys

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

for source, src, trg in chunks(parts, n=3):
    print("    ", end="")
    print('"%s %s %s"' % (source, src, trg))
    pass

print(")")
print()
