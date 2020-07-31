import sys

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, air_geocode as geocode
from multiprocessing import Pool, cpu_count


def clean_boro(b):
    """
    Limit to NYC and make Staten Island two words
    """
    if b == "STATENISLAND":
        b = "STATEN ISLAND"
    if b not in ["BRONX", "MANHATTAN", "BROOKLYN", "QUEENS", "STATEN ISLAND"]:
        b = None
    if b != None:
        b = b.title()
    return b


def clean_house(s):
    """
    Fill empty or 0-start house nums with ' ' and take first house num in list
    """
    s = " " if s == None else s
    s = "" if s[0] == "0" else s
    s = (
        re.sub(r"\([^)]*\)", "", s)
        .replace(" - ", "-")
        .split("(", maxsplit=1)[0]
        .split("/", maxsplit=1)[0]
    )
    return s


def clean_street(s):
    """
    Fill empty street with '', clean special characters, and take first in list
    """
    s = "" if s == None else s
    s = "JFK INTERNATIONAL AIRPORT" if "JFK" in s else s
    s = (
        re.sub(r"\([^)]*\)", "", s)
        .replace("'", "")
        .replace("VARIOUS", "")
        .replace("LOCATIONS", "")
        .split("(", maxsplit=1)[0]
        .split("/", maxsplit=1)[0]
    )
    return s


def parse_streetname(x, n):
    """
    Identify intersections using key words and find the n-th
    intersecting street.
    """
    x = "" if x is None else x
    if (
        ("&" in x)
        | (" AND " in x.upper())
        | ("CROSS" in x.upper())
        | ("CRS" in x.upper())
    ):
        x = re.split("&| AND | and |CROSS|CRS", x)[n]
    else:
        x = ""
    return x


def _import() -> pd.DataFrame:
    """
    Download and format DEP CATS permit data from open data API

    Gets raw data from API and saves to output/raw.csv
    Checks raw data to ensure necessary columns are included
    Gets boroughs from zipcodes, and cleans and parses addresses

    Returns:
    df (DataFrame): Contains fields requestid, applicationid,
        requesttype, housenum, hnum, streetname, sname, borough, 
        bin, block, lot, ownername, expiration_date, make, 
        model, burnermake, burnermodel, primaryfuel, secondaryfuel, 
        quantity, issue_date, status, premisename, streetname_1,
        streetname_2
    """
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
        "premisename"
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

    df["borough"] = df.borough.apply(clean_boro)
    df["borough"] = np.where(
        (df.streetname.str.contains("JFK")) & (df.borough == None), "Queens", df.borough
    )
    df["hnum"] = df.housenum.astype(str).apply(clean_house)
    df["sname"] = df.streetname.astype(str).apply(clean_street)

    df["address"] = df.hnum + " " + df.sname

    df["hnum"] = df.address.apply(get_hnum)
    df["sname"] = df.address.apply(get_sname)

    df["streetname_1"] = (
        df["address"].apply(lambda x: parse_streetname(x, 0)).apply(get_sname)
    )
    df["streetname_2"] = (
        df["address"].apply(lambda x: parse_streetname(x, -1)).apply(get_sname)
    )
    df["status"] = df["status"].apply(lambda x: x.strip())

    return df


def _geocode(df: pd.DataFrame) -> pd.DataFrame:
    """ 
    Geocode cleaned DEP CATS permit data using helper/geocode()

    Parameters: 
    df (DataFrame): Contains data  with
                    hnum and sname parsed
                    from address
    Returns:
    df (DataFrame): Contains input fields along
                    with geosupport fields
    """
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
    """ 
    Output geocoded data to stdout for transfer to postgres

    Parameters: 
    df (DataFrame): Contains input fields along
                    with geosupport fields
    """
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
