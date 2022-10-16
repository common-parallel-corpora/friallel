
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
from pprint import pprint


def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'

def generate_task_reports(fs_client):
    counts = {}
    for task in fs_client.collection('annotation-tasks').stream():
        task_data = task.to_dict()
        collection_id = task_data['collection_id']
        task_type = task_data['type']
        if task_type == 'verification':
            key = f"{collection_id}_{task_type}_level_{task_data['verification_level']}_{task_data['status']}"
        else:
            key = f"{collection_id}_{task_type}_{task_data['status']}"

        if key not in counts:
            counts[key] = 0
        counts[key] += 1
    print("TASKS")
    pprint(counts)

def generate_workflow_reports(fs_client):
    counts = {}
    for workflow in fs_client.collection('workflows').stream():
        workflow_data = workflow.to_dict()
        workflow_status = workflow_data['status']
        key = f"{workflow_status}"
        if key not in counts:
            counts[key] = 0
        counts[key] += 1
    print("WORKFLOWS")
    pprint(counts)

def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    generate_task_reports(fs_client)
    generate_workflow_reports(fs_client)
    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--dataset-names", nargs="+")
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)