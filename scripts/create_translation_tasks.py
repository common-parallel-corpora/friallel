
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils


def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'

def generate_sentence_ids(fs_client, dataset_name):
    sentences_ref = fs_client.collection(get_collection_name(dataset_name))
    for sentence_ref in sentences_ref.stream():
        yield sentence_ref.id


def main(args):
    fs_client = firebase_utils.get_firestore_client()
    priority = 0
    for round_ix in range(3):
        for dataset_name in args.dataset_names:
            for document_id in generate_sentence_ids(fs_client, dataset_name):
                translation_task_doc_data = {
                    "collection_id": get_collection_name(dataset_name),
                    "document_id": document_id,
                    "target_lang": args.target_lang,
                    "status": "unassigned",
                    "priority": priority
	            }
                document = fs_client.document(f'tanslation-tasks/{priority:010}')
                document.create(translation_task_doc_data)
                priority += 1
    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--dataset-names", nargs="+")
    parser.add_argument("--strategy", choices=['3-tasks-per-sentence'])
    parser.add_argument("--target-lang")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)