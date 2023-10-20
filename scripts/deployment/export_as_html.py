#! /usr/bin/python3

import argparse
import logging
import requests

from lxml import etree
from typing import List

# currently only meant for DSGS EMSL v2 model


HTML_TEMPLATE = """<!doctype html>

<html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">

        <style>
            /*https://www.w3schools.com/css/css_table.asp*/
            #translations {{
              font-family: Arial, Helvetica, sans-serif;
              border-collapse: collapse;
              width: 100%;
            }}

            #translations td, #translations th {{
              border: 1px solid #ddd;
              padding: 8px;
            }}

            #translations tr:nth-child(even){{background-color: #f2f2f2;}}

            #translations tr:hover {{background-color: #ddd;}}

            #translations th {{
              padding-top: 12px;
              padding-bottom: 12px;
              text-align: left;
              background-color: #04AA6D;
              color: white;
            }}
        </style>

  <title>Automatic translations</title>
</head>

<body>
   <table id="translations">
  <tr>
    <th>Video</th>
    <th>Source</th>
    <th>Machine translation</th>
    <th>Reference</th>
  </tr>
  {rows}
</table>
</body>
</html>
"""

TR_TEMPLATE = """<tr>
    <td>
         <video width="320" height="240" controls>
             <source src="{video_url}" type="video/mp4">
         </video>
    </td>
    <td>{source}</td>
    <td>{translation}</td>
    <td>{reference}</td>
  </tr>"""


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--xml-url", type=str, help="Public URL of XML with video links", required=True)

    parser.add_argument("--sources", type=str, help="Inputs to MT system", required=True)
    parser.add_argument("--translations", type=str, help="Model translations", required=True)
    parser.add_argument("--references", type=str, help="Reference translations", required=True)

    parser.add_argument("--num-sentences", type=int, help="Limit number of sentences shown (default: all)",
                        required=False, default=-1)

    args = parser.parse_args()

    return args


def read_video_urls_from_xml(url: str) -> List[str]:
    """

    :param url:
    :return:
    """
    video_urls = []  # type: List[str]

    res = requests.get(url)
    root = etree.fromstring(res.content)

    for seg_element in root.xpath("//src/p/seg"):
        video_urls.append(seg_element.text)

    return video_urls


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    video_urls = read_video_urls_from_xml(args.xml_url)

    with open(args.sources) as infile:
        sources = infile.readlines()
        sources = [s.strip() for s in sources]

    with open(args.translations) as infile:
        translations = infile.readlines()
        translations = [t.strip() for t in translations]

    with open(args.references) as infile:
        references = infile.readlines()
        references = [r.strip() for r in references]

    if args.num_sentences > 0:
        # then in all lists there must be at least the requested number of items
        for l in [sources, translations, references, video_urls]:
            assert len(l) >= args.num_sentences
    else:
        # else all lists must have the same length
        assert len(video_urls) == len(translations) == len(references) == len(sources), \
            "video_urls: %d, translations: %d, references: %d, sources: %d" % (len(video_urls), len(translations), len(references), len(sources))

    rows = []

    for video_url, source, translation, reference in zip(video_urls, sources, translations, references):
        row = TR_TEMPLATE.format(video_url=video_url, source=source, translation=translation, reference=reference)
        rows.append(row)

    logging.debug("Example row:")
    logging.debug(rows[0])

    rows_as_string = "\n".join(rows)

    document_string = HTML_TEMPLATE.format(rows=rows_as_string)

    print(document_string)


if __name__ == '__main__':
    main()
