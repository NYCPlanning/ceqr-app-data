import sys

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, clean_street, clean_house, clean_boro_name, geocode
from multiprocessing import Pool, cpu_count

def _import() -> pd.DataFrame:
    url = "https://data.cityofnewyork.us/api/views/f4rp-2kvy/rows.csv"
    cols = [
        "requestid",
        "applicationid",
        "requesttype",
        "house",
        "street",
        "borough",
        "bin",
        "block",
        "lot",
        "ownername",
        "expirationdate",
        "make",
        "model",
        "burnermake",
        "burnermodel",
        "primaryfuel",
        "secondaryfuel",
        "quantity",
        "issuedate",
        "status",
        "premisename",
    ]

    df = pd.read_csv(url, dtype=str, engine="c")
    df.columns = [i.lower() for i in df.columns]
    for col in cols:
        assert col in df.columns

    df.to_csv("output/raw.csv", index=False)

    df.rename(
        columns={
            "house": "housenum",
            "street": "streetname",
            "issuedate": "issue_date",
            "expirationdate": "expiration_date",
        },
        inplace=True,
    )

    df["borough"] = df.borough.apply(clean_boro_name)
    df["borough"] = np.where(
        (df.streetname.str.contains("JFK")) & (df.borough == None), "Queens", df.borough
    )

    df["address"] = df.housenum.astype(str).apply(clean_house) + \
                    " " + df.streetname.astype(str).apply(clean_street)
    df["hnum"] = df.address.apply(get_hnum)
    df["sname"] = df.address.apply(get_sname)
    
    df["status"] = df["status"].apply(lambda x: x.strip())

    return df


def _geocode(df: pd.DataFrame) -> pd.DataFrame:
    # geocoding
    records = df.to_dict("records")
    del df

    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, 10000)

    df = pd.DataFrame(it)
    df = df[df["geo_grc"] != "71"]
    df["geo_address"] = None
    df["geo_longitude"] = pd.to_numeric(df["geo_longitude"], errors="coerce")
    df["geo_latitude"] = pd.to_numeric(df["geo_latitude"], errors="coerce")
    df["geo_bbl"] = df.geo_bbl.apply(
        lambda x: None if (x == "0000000000") | (x == "") else x
    )
    return df


def _output(df: pd.DataFrame):
    schema_name = "dep_cats_permits"
    cols = [
        "requestid",
        "applicationid",
        "requesttype",
        "ownername",
        "expiration_date",
        "make",
        "model",
        "burnermake",
        "burnermodel",
        "primaryfuel",
        "secondaryfuel",
        "quantity",
        "issue_date",
        "status",
        "premisename",
        "housenum",
        "streetname",
        "address",
        "streetname_1",
        "streetname_2",
        "borough",
        "geo_housenum",
        "geo_streetname",
        "geo_address",
        "geo_bbl",
        "geo_bin",
        "geo_latitude",
        "geo_longitude",
        "geo_x_coord",
        "geo_y_coord",
        "geo_function",
    ]
    df[cols].to_csv(sys.stdout, sep="|", index=False)


if __name__ == "__main__":

    df = _import()
    df = _geocode(df)
    _output(df)
