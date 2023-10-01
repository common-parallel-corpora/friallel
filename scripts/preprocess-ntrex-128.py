from argparse import ArgumentParser
import csv
import shutil
from pathlib import Path

def main(args):
    Path(args.output_dir).mkdir(exist_ok=True, parents=True)
    with open(args.mapping_file) as f:
        reader = csv.DictReader(f)
        for row in reader:
            shutil.copy(
                Path(args.input_dir) / row['orig-fname'],
                Path(args.output_dir) / f"{row['combined_code']}"
            )

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--mapping-file", required=True)
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    main(args)
