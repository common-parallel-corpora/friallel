import argparse
from pathlib import Path
import torch
import numpy as np
import scipy
import scipy.spatial
import scipy.optimize
from sklearn.metrics.pairwise import cosine_distances
from tqdm import tqdm
import ssl
ssl._create_default_https_context = ssl._create_unverified_context
import editdistance



def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_files", nargs=2)
    parser.add_argument("--output-files", nargs=2, required=True)
    return parser.parse_args()


def read_file_lines(p):
    lines = []
    with open(p, encoding="utf8") as f:
        for line in f:
            for c in ['\"', '\'', "\."]:
                line = line.replace(c, " ")
            lines.append(line.strip())
    return lines

def lines_to_vectors(lines):
    tokenizer = torch.hub.load('huggingface/pytorch-transformers', 'tokenizer', 'bert-base-uncased')    # Download vocabulary from S3 and cache.
    model = torch.hub.load('huggingface/pytorch-transformers', 'model', 'bert-base-uncased')    # Download model and configuration from S3 and cache.
    vectors = []
    for l in tqdm(lines):
        line_tokens = torch.tensor([tokenizer.encode(l)])
        output = model(line_tokens)
        output_vectors = output.last_hidden_state.detach().numpy()
        vector = np.sum(output_vectors, axis=(0,1))
        vectors.append(vector)
    return np.vstack(vectors)


def build_edit_distance_matrix(lines_1, lines_2):
    n1 = len(lines_1)
    n2 = len(lines_2)
    distance_matrix = np.zeros((n1, n2))
    for i in tqdm(range(n1)):
        for j in range(n2):
            distance_matrix[i, j] = editdistance.eval(lines_1[i], lines_2[j])
    return distance_matrix


def main(args):
    p1, p2 = (Path(p) for p in args.input_files)
    lines_1 = read_file_lines(p1)
    lines_2 = read_file_lines(p2)
    # print("computing vectors")
    #vectors_1 = lines_to_vectors(lines_1)
    #vectors_2 = lines_to_vectors(lines_2)
    print("computing distance matrix")
    
    # distance_matrix = cosine_distances(vectors_1, vectors_2)
    distance_matrix = build_edit_distance_matrix(lines_1, lines_2)
    # distance_matrix = scipy.spatial.distance_matrix(vectors_1, vectors_2)
    print("computing assignment")
    ind1, ind2 = scipy.optimize.linear_sum_assignment(distance_matrix)
    for p in args.output_files:
        Path(p).parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(args.output_files[0], ind1.astype(int), fmt='%d')
    np.savetxt(args.output_files[1], ind2.astype(int), fmt='%d')
    print("done")


if __name__ == '__main__':
    args = parse_args()
    main(args)
