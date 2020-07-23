import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, air_geocode as geocode
from multiprocessing import Pool, cpu_count


def clean_address(x):
    x = "" if x is None else x
    sep = ["|", "&", "@", " AND "]
    for i in sep:
        x = x.split(i, maxsplit=1)[0]
    return x


def clean_streetname(x, n):
    x = "" if x is None else x
    if ("&" in x) | (" AND " in x.upper()):
        x = re.split("&| AND | and ", x)[n]
    else:
        x = ""
    return x


def _import() -> pd.DataFrame:
    """
    Download and format nysdec title v data from open data API
    Gets raw data from API and saves to output/raw.csv
    Checks raw data to ensure necessary columns are included
    Gets boroughs from zipcodes, and cleans and parses addresses
    Returns:
    df (DataFrame): Contains fields facility_name,
        permit_id, url_to_permit_text, facility_location,
        facility_city, facility_state, zipcode, issue_date,
        expiration_date, location, address, borough, 
        hnum, sname, streetname_1, streetname_2
    """
    url = "https://data.ny.gov/api/views/4n3a-en4b/rows.csv"
    cols = [
        "facility_name",
        "permit_id",
        "url_to_permit_text",
        "facility_location",
        "facility_city",
        "facility_state",
        "facility_zip",
        "issue_date",
        "expiration_date",
        "location",
    ]
    df = pd.read_csv(url, dtype=str, engine="c", index_col=False)
    df.to_csv("output/raw.csv", index=False)

    czb = pd.read_csv("../_data/city_zip_boro.csv", dtype=str, engine="c")

    df.columns = [i.lower().replace(" ", "_") for i in df.columns]
    for col in cols:
        assert col in df.columns

    # generate inputs for geocoding
    df = df.rename(columns={"facility_zip": "zipcode"})
    df = df.loc[df.zipcode.isin(czb.zipcode.tolist()), :]
    df["borough"] = df.zipcode.apply(
        lambda x: czb.loc[czb.zipcode == x, "boro"].tolist()[0]
    )
    df["address"] = df["facility_location"].astype(str).apply(clean_address)
    df["hnum"] = (
        df["address"]
        .astype(str)
        .apply(get_hnum)
        .apply(lambda x: x.split("/", maxsplit=1)[0] if x != None else x)
    )
    df["sname"] = df["address"].astype(str).apply(get_sname)
    df["streetname_1"] = (
        df["facility_location"]
        .astype(str)
        .apply(lambda x: clean_streetname(x, 0))
        .apply(get_sname)
    )
    df["streetname_2"] = (
        df["facility_location"]
        .astype(str)
        .apply(lambda x: clean_streetname(x, -1))
        .apply(get_sname)
    )
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


def _output(df):
    cols = [
        "facility_name",
        "permit_id",
        "url_to_permit_text",
        "facility_location",
        "address",
        "housenum",
        "streetname",
        "streetname_1",
        "streetname_2",
        "facility_city",
        "facility_state",
        "borough",
        "zipcode",
        "issue_date",
        "expiration_date",
        "location",
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
    df = df.rename(columns={"hnum":"housenum", "sname":"streetname"})
    df[cols].to_csv(sys.stdout, index=False)


if __name__ == "__main__":
    df = _import()
    df = _geocode(df)
    _output(df)
