def write_to_csv(df, path):
    df.write_csv(file = path)

def read_from_csv(path):
    df = polars.read_csv(path)
    return df
