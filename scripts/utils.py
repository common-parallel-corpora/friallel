def single(a):
    if len(a) != 1:
        raise ValueError(f"The specified array has {len(a)} elements. It should have 1 element")
    return a[0]