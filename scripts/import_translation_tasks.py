
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
import datetime


def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'

def generate_sentence_ids(fs_client, dataset_name):
    sentences_ref = fs_client.collection(get_collection_name(dataset_name))
    for sentence_ref in sentences_ref.stream():
        yield sentence_ref.id

def load_annotation_tasks(fs_client, args):
    annotation_tasks_by_sentence = {}
    query = fs_client.collection("annotation-tasks").where(
        "type", "==", "translation"
    ).where(
        "collection_id", "==", get_collection_name(args.dataset_name)
    ).where(
        "target_lang", "==", args.translation_target_lang
    )
    #.where(
    #    "status", "==", "unassigned"
    #)

    for task in query.stream():
        task_data = task.to_dict()
        sentence_id = task_data['document_id']
        task_data["id"] = task.id
        annotation_tasks_by_sentence[sentence_id] = task_data
    return annotation_tasks_by_sentence


def load_user_ids_by_email(fs_client):
    d = {}
    for user_doc in fs_client.collection("users").stream():
        email = user_doc.to_dict()['email']
        d[email] = user_doc.id
    return d


def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    annotation_tasks = load_annotation_tasks(fs_client, args)
    userIdsByEmail = load_user_ids_by_email(fs_client)
    print(f"Fetched {len(annotation_tasks)} annotation tasks.")
    print(f"Fetched {len(userIdsByEmail)} users")
    with open(args.input_csv_file_path) as inputf, open(args.output_csv_report_path, "w") as reportf:
        reader = csv.DictReader(inputf)
        output_field_names = reader.fieldnames.copy()
        output_field_names.extend(["import_status", "task_id"])
        writer = csv.DictWriter(reportf, output_field_names)
        writer.writeheader()
        updated_date = datetime.datetime.now(datetime.timezone.utc)
        for row in reader:
            sentence_id = row[args.input_csv_sentence_id_colname]
            if sentence_id in annotation_tasks:
                task_data = annotation_tasks[sentence_id]
                task_doc = fs_client.document(f"annotation-tasks/{task_data['id']}")
                task_doc.set({
                    "assignee_id": userIdsByEmail[row[args.input_csv_translator_email_colname]],
                    "translated_sentence": row[args.input_csv_translation_colname],
                    "status": "completed",
                    "updated_date": updated_date
                }, merge=True)
                print(f"Updated annotation task for sentence#{sentence_id}")
                row['import_status'] = "OK"
                row['task_id'] = task_data['id']
            else:
                print(f"Could not find annotation task for sentence#{sentence_id}")
                row['import_status'] = "ERROR"
            writer.writerow(row)
    

def parse_args():
    parser = ArgumentParser("""Imports annotation tasks completed outside of this system from CSV files.""")
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    parser.add_argument(
        "--input-csv-file-path", 
        required=True, 
        help="CSV file to import the translation tasks from"
    )
    parser.add_argument(
        "--output-csv-report-path", 
        required=True, 
        help="CSV File to contain the import report"
    )
    parser.add_argument(
        "--dataset-name", 
        required=True,
        help="Name of the dataset"
    )
    parser.add_argument(
        "--input-csv-sentence-id-colname", 
        default='sentence_id', 
        help="Name of the column that contains the sentence id"
    )
    parser.add_argument(
        "--input-csv-translator-email-colname", 
        default="translator_email",
        help="Name of the column that contains the translator email address"
    )
    parser.add_argument(
        "--input-csv-translation-colname", 
        required=True,
        help="Name of the column that contains the translation"
    )
    parser.add_argument(
        "--translation-target-lang", 
        required=True,
        help="Name of the column that contains the translation target language"
    )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)