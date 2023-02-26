
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
from datetime import datetime
import parallel_corpus_utils


def load_user_ids_by_email(fs_client):
    d = {}
    for user_doc in fs_client.collection("users").stream():
        email = user_doc.to_dict()['email']
        d[email] = user_doc.id
    return d


def create_dataset_collection(args):

    batch.commit()
    for sentence_ix, sentence_doc_data in generate_dataset_sentences(args):
        # store_sentence(fs_client, args.dataset_name, sentence_ix, sentence_doc_data)
        document_ref = fs_client.document(f'dataset-{args.dataset_name}/{sentence_ix:010}')
        # document.create(sentence_doc_data)
        batch.set(document_ref, sentence_doc_data)
        if len(batch) >= args.batch_size:
            print(f"Inserting {len(batch)} sentences")
            batch.commit()
            batch = fs_client.batch()
    
    if len(batch) >= 0:
        print(f"Inserting {len(batch)} workflows")
        batch.commit()


        


def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    user_ids_by_email = load_user_ids_by_email(fs_client)
    print(user_ids_by_email)
    if args.user_email in user_ids_by_email:
        user_doc_ref = fs_client.document(f'users/{user_ids_by_email[args.user_email]}')
        user_doc_ref.update({
            "translation_from_languages": args.langs
        })
    else:
        print(f"Unknown user email: {args.user_email}")
    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    parser.add_argument("--user-email", required=True)
    parser.add_argument("--langs", nargs="+", required=True)
    
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)