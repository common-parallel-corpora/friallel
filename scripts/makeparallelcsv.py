
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path
import parallel_corpus_utils

def main(args):
    column_names = [Path(p).name for p in args.data_files]
    with open(args.output_file, "w") as output_f:
        writer = csv.DictWriter(output_f, fieldnames=column_names)
        writer.writeheader()
        for parallel_line in parallel_corpus_utils.generate_parallel_lines(args.data_files):
            row = {}
            for col_ix in range(len(column_names)):
                row[column_names[col_ix]] = parallel_line[col_ix]
            writer.writerow(row)

    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("data_files", nargs="+")
    parser.add_argument("--output-file", required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)