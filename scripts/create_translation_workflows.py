
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
import random


def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'

def generate_sentence_ids(fs_client, dataset_name):
    sentences_ref = fs_client.collection(get_collection_name(dataset_name))
    for sentence_ref in sentences_ref.stream():
        yield sentence_ref.id


def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    priority = args.initial_priority

    batch = fs_client.batch()
    batch.commit()

    for dataset_name in args.dataset_names:
        if args.random_subset_size != -1:
            print(f"Inserting workflows for a subset of {args.random_subset_size} sentences.")
            sentence_ids = list(generate_sentence_ids(fs_client, dataset_name))
            sentence_ids = random.sample(sentence_ids, k=args.random_subset_size)
        else:
            sentence_ids = generate_sentence_ids(fs_client, dataset_name)

        for document_id in sentence_ids:
            collection_id = get_collection_name(dataset_name)
            translation_workflow_doc_ref = fs_client.collection('workflows').document()
            translation_workflow_doc_data = {
                "collection_id": collection_id,
                "document_id": document_id,
                "target_lang": args.target_lang,
                "status": "active",
                "type": args.workflow_name,
                "priority": priority
            }
            batch.set(translation_workflow_doc_ref, translation_workflow_doc_data)

            if len(batch) >= args.batch_size:
                print(f"Inserting {len(batch)} workflows")
                batch.commit()
                batch = fs_client.batch()
            # fs_client.collection('workflows').add(translation_workflow_doc_data)
            priority += 1

    if len(batch) >= 0:
        print(f"Inserting {len(batch)} workflows")
        batch.commit()
    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    parser.add_argument("--dataset-names", nargs="+")
    parser.add_argument("--workflow-name", choices=['default-translation-workflow'], required=True)
    parser.add_argument("--initial-priority", type=int, required=True)
    parser.add_argument("--batch-size", type=int, default=100)
    parser.add_argument("--target-lang", required=True)
    parser.add_argument("--random-subset-size", required=False, default=-1, type=int)
    
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)