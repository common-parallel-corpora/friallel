import argparse
from pathlib import Path
import torch
import numpy as np
import scipy
import scipy.spatial
import scipy.optimize
from tqdm import tqdm
import ssl
ssl._create_default_https_context = ssl._create_unverified_context


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_files", nargs=2)
    parser.add_argument("--output-files", nargs=2, required=True)
    return parser.parse_args()


def read_file_lines(p):
    with open(p) as f:
        return [l.strip() for l in f]# [:10]


def lines_to_vectors(lines):
    tokenizer = torch.hub.load('huggingface/pytorch-transformers', 'tokenizer', 'bert-base-uncased')    # Download vocabulary from S3 and cache.
    model = torch.hub.load('huggingface/pytorch-transformers', 'model', 'bert-base-uncased')    # Download model and configuration from S3 and cache.
    vectors = []
    for l in tqdm(lines):
        line_tokens = torch.tensor([tokenizer.encode(l)])
        # print(line_tokens.shape)
        output = model(line_tokens)
        # print(output)
        vector = output.pooler_output
        # print(vector.shape)
        vectors.append(vector.detach().numpy())
    return np.vstack(vectors)


def main(args):
    p1, p2 = (Path(p) for p in args.input_files)
    lines_1 = read_file_lines(p1)
    lines_2 = read_file_lines(p2)
    print("computing vectors")
    vectors_1 = lines_to_vectors(lines_1)
    vectors_2 = lines_to_vectors(lines_2)
    print("computing distance matrix")
    distance_matrix = scipy.spatial.distance_matrix(vectors_1, vectors_2)
    print("computing assignment")
    ind1, ind2 = scipy.optimize.linear_sum_assignment(distance_matrix)
    np.savetxt(args.output_files[0], ind1.astype(int), fmt='%d')
    np.savetxt(args.output_files[1], ind2.astype(int), fmt='%d')
    print("done")


if __name__ == '__main__':
    args = parse_args()
    main(args)
