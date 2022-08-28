
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
from datetime import datetime
import parallel_corpus_utils


def create_dataset_collection(args):
    fs_client = firebase_utils.get_firestore_client()
    for sentence_ix, sentence_doc_data in generate_dataset_sentences(args):
        store_sentence(fs_client, args.dataset_name, sentence_ix, sentence_doc_data)


def generate_dataset_sentences(args):
    file_list = [
        p for p in Path(args.dataset_root_dir).iterdir() 
        if p.is_file() and \
            (
                (not args.langs) or \
                p.stem in args.langs
            )
    ]

    lang_list = [p.stem for p in file_list]

    for sentence_ix, parallel_line in enumerate(parallel_corpus_utils.generate_parallel_lines(file_list)):
        sentence_doc_data = {
            "tranlations": []
        }
        for tr_ix, sentence_variant in enumerate(parallel_line):
            lang = lang_list[tr_ix]
            sentence_doc_data["tranlations"].append(
                {
                    "user_id": "REFERENCE",
                    "lang": lang,
                    "translation": sentence_variant,
                    "created": datetime.utcnow(),
                    "updated": datetime.utcnow(),
                }
            )
        yield sentence_ix, sentence_doc_data
        


def store_sentence(fs_client, dataset_name, sentence_id, sentence_document_data):
    document = fs_client.document(f'dataset-{dataset_name}/{sentence_id:010}')
    document.create(sentence_document_data)


def main(args):
    create_dataset_collection(args)
    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--dataset-root-dir", required=True)
    parser.add_argument("--dataset-name", required=True)
    parser.add_argument("--langs", nargs="*")
    
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)