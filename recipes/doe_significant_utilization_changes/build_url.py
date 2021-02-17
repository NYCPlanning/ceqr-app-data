import pandas as pd
import numpy as np
import sys
import os

do_s3_endpoint=os.environ.get('DO_S3_ENDPOINT')

def _import() -> pd.DataFrame:
    """
    Download scraped url data from DigitalOcean data library
    and saves to output/raw.csv

    Returns:
    df (DataFrame): Contains fields 
    """
    df = pd.read_csv(f"{do_s3_endpoint}/datasets/doe_pepmeetingurls/latest/doe_pepmeetingurls.csv", dtype=str, index_col=False)
    df.fillna('', inplace=True)
    df.to_csv("output/sharepoint_urls.csv")
    return df

def _output(df):
    cols=[
        "url",
        "school_year",
        "readable_url",
        "date"
    ]
    df.to_csv(sys.stdout, sep='|', index=False)

if __name__ == "__main__":
    df = _import()
    _output(df)