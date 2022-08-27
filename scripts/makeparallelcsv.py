
import sys
from argparse import ArgumentParser
import csv
from pathlib import Path


def generate_file_lines(fpath):
    with open(fpath) as f:
        line = f.readline()
        while line:
            yield line
            line = f.readline()


def generate_parallel_files(args):
    line_generators = [generate_file_lines(f) for f in args.data_files]
    parallel_lines = None
    try:
        while True:
            parallel_lines = []
            for g in line_generators:
                parallel_lines.append(next(g).strip())
            yield parallel_lines
    except StopIteration:
        pass



def main(args):
    column_names = [Path(p).name for p in args.data_files]
    with open(args.output_file, "w") as output_f:
        writer = csv.DictWriter(output_f, fieldnames=column_names)
        writer.writeheader()
        for parallel_line in generate_parallel_files(args):
            row = {}
            for col_ix in range(len(column_names)):
                row[column_names[col_ix]] = parallel_line[col_ix]
            writer.writerow(row)

    

def parse_args():
    parser = ArgumentParser()
    parser.add_argument("data_files", nargs="+")
    parser.add_argument("--output-file")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    main(args)