
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import firebase_utils
from pprint import pprint
import itertools



def get_collection_name(dataset_name):
    return f'dataset-{dataset_name}'

def load_users(fs_client):
    users = []
    for user_doc in fs_client.collection("users").stream():
        datum = user_doc.to_dict()
        datum['id'] = user_doc.id
        users.append(datum)
    return users

def generate_completed_tasks(fs_client, users):
    for task in fs_client.collection('annotation-tasks').order_by("updated_date").stream():
        task_data = task.to_dict()
        user = [u for u in users if u['id'] == task_data['assignee_id']][0]
        
        yield {
            "year": task_data['updated_date'].year,
            "month": task_data['updated_date'].month,
            "user": user,
            "completed_task": task_data
        }


def main(args):
    fs_client = firebase_utils.get_firestore_client(args.env)
    users = load_users(fs_client)
    completed_tasks = list(generate_completed_tasks(fs_client, users))
    report_periods = sorted(
        set([ (d["year"], d["month"]) for d in completed_tasks]),
    )

    csv_writer = csv.DictWriter(sys.stdout, ["year", "month", "collection", "task_type", "translator_id", "translator_email", "completed_count"])
    csv_writer.writeheader()
    for period in report_periods:
        period_datums = [
            d for d in completed_tasks
            if (d["year"], d["month"]) == period
        ]
        distinct_collection_ids = set(d['completed_task']['collection_id'] for d in period_datums)
        distinct_types = set(d['completed_task']['type'] for d in period_datums)
        distinct_users = set(d['user']['id'] for d in period_datums)
        for collection_id, task_type, user_id in itertools.product(
            distinct_collection_ids, distinct_types, distinct_users):
            user_email = [u['email'] for u in users if u['id']==user_id][0]
            count = len([
                d for d in period_datums 
                if d['completed_task']['collection_id'] == collection_id and \
                    d['completed_task']['type'] == task_type and \
                    d['user']['id'] == user_id
            ])
            output_row = {
                "year": period[0],
                "month": period[1],
                "collection": collection_id, 
                "task_type": task_type, 
                "translator_id": user_id, 
                "translator_email": user_email, 
                "completed_count": count
            }
            csv_writer.writerow(output_row)
            
            # print(f"\t{collection_id}, {task_type}, {user_id}, {user_email}, {count}")


def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--dataset-names", nargs="+")
    parser.add_argument("--env", choices=['dev', 'prod'], required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)