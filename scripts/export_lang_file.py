import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
from pprint import pprint
from pprint import pprint


def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'


def load_users(fs_client):
    users = []
    for user_doc in fs_client.collection("users").stream():
        datum = user_doc.to_dict()
        datum['id'] = user_doc.id
        users.append(datum)
    return users


def generate_completed_tasks(fs_client, users, dataset_name):
    dataset_collection_id = get_collection_name(dataset_name)
    completed_task_query = fs_client.collection('annotation-tasks').where("collection_id", "==", dataset_collection_id).where('status', '==', 'completed')
    for task in completed_task_query.stream():
        task_data = task.to_dict()
        user = [u for u in users if u['id'] == task_data['assignee_id']][0]
        
        yield {
            "collection_id": dataset_collection_id,
            "document_id": task_data['document_id'],
            "task_type": task_data['type'],
            "verification_level": task_data.get('verification_level', None),
            "translated_sentence": task_data['translated_sentence'],
            "target_lang": task_data['target_lang'],
            "updated_date": task_data["updated_date"],
            "user": user
        }


def generate_dataset_sentences(fs_client, users, dataset_name):
    dataset_collection_id = get_collection_name(dataset_name)
    for sentence in fs_client.collection(dataset_collection_id).stream():
        sentence_doc = sentence.to_dict()
        yield {
            "id": sentence.id,
            "translations": sentence_doc['translations']
        }

def single_or_blank(a):
    if len(a) > 1:
        raise ValueError("At most, a single element is expected in the array")
    if len(a) == 1:
        return a[0]
    return ""


def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    users = load_users(fs_client)
    
    completed_tasks_by_sid = {}
    reference_sentences_by_sid = {}

    for ref_s in generate_dataset_sentences(fs_client, users, args.dataset_name):
        reference_sentences_by_sid[ref_s["id"]] = ref_s

    for completed_task in generate_completed_tasks(fs_client, users, args.dataset_name):
        sid = completed_task['document_id']
        if sid not in completed_tasks_by_sid:
            completed_tasks_by_sid[sid] = []
        completed_tasks_by_sid[sid].append(completed_task)

    field_extractors = {
        "sid": lambda sid, refs, tasks: sid
    }

    field_extractors[f"translated_text"] = \
            lambda sid, refs, tasks: \
                sorted([t for t in tasks if t['task_type'] in {'translation', 'verification'}], key=lambda x: x['updated_date'])[-1]['translated_sentence'].replace("\n", " ")


    csv_writer = csv.DictWriter(sys.stdout, ["translated_text"], extrasaction='ignore')
    #csv_writer.writeheader()
    field_names = list(field_extractors.keys())

    for sid in sorted(reference_sentences_by_sid.keys()):
        row = {}
        for field_name in field_names:
            row[field_name] = field_extractors[field_name](sid, reference_sentences_by_sid[sid], completed_tasks_by_sid[sid])
        csv_writer.writerow(row)
        #print(row[f"translated_text"])
        
        


def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--dataset-name", required=True)
    parser.add_argument("--target-lang", default='nqo_Nkoo')
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)