import argparse
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-file", required=True)
    parser.add_argument("--order-file", required=True)
    parser.add_argument("--output-file", required=True)
    return parser.parse_args()

def main(args):
    input_lines = []
    output_orders = []

    with open(args.input_file, encoding="utf8") as f:
        line = f.readline()
        while line:
            input_lines.append(line)
            line = f.readline()

    with open(args.order_file, encoding="utf8") as f:
        line = f.readline()
        while line:
            output_orders.append(int(line))
            line = f.readline()
    print(f"read {len(input_lines)} input lines")
    print(f"read {len(output_orders)} order lines")

    Path(args.output_file).parent.mkdir(exist_ok=True, parents=True)
    with open(args.output_file, "w", encoding="utf8") as of:
        for ix in output_orders:
            of.write(input_lines[ix])
    print("done")



    

if __name__ == '__main__':
    args = parse_args()
    main(args)
