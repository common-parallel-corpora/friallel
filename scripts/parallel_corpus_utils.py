def generate_file_lines(fpath):
    with open(fpath) as f:
        line = f.readline()
        while line:
            yield line
            line = f.readline()


def generate_parallel_lines(data_files):
    line_generators = [generate_file_lines(f) for f in data_files]
    parallel_lines = None
    try:
        while True:
            parallel_lines = []
            for g in line_generators:
                parallel_lines.append(next(g).strip())
            yield parallel_lines
    except StopIteration:
        pass