import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, clean_address, find_intersection, find_stretch, geocode
from multiprocessing import Pool, cpu_count


def _import() -> pd.DataFrame:
    """
    Download and format nysdec state facility permit data from open data API
    Gets raw data from API and saves to output/raw.csv
    Checks raw data to ensure necessary columns are included
    Gets boroughs from zipcodes, and cleans and parses addresses
    Returns:
    df (DataFrame): Contains fields facility_name,
        permit_id, url_to_permit_text, facility_location,
        facility_city, facility_state, zipcode, 
        issue_date, expiration_date, location, 
        address, borough, hnum, sname, 
        streetname_1, streetname_2
    """
    url = "https://data.ny.gov/api/views/2wgt-bc53/rows.csv"
    cols = [
        "facility_name",
        "permit_id",
        "url_to_permit_text",
        "facility_location",
        "facility_city",
        "facility_state",
        "facility_zip",
        "issue_date",
        "expire_date",
        "location",
    ]
    df = pd.read_csv(url, dtype=str, engine="c", index_col=False)
    df.to_csv("output/raw.csv", index=False)

    # Open lookup between zip codes and boroughs
    czb = pd.read_csv("../_data/city_zip_boro.csv", dtype=str, engine="c")

    # Read and filter corrections file
    corr = pd.read_csv("../_data/air_corr.csv", dtype=str, engine="c")
    corr_dict = corr.loc[corr.datasource == "nysdec_state_facility_permits", :].to_dict('records')

    df.columns = [i.lower().replace(" ", "_") for i in df.columns]
    for col in cols:
        assert col in df.columns, f"Missing {col} in input data"

    df = df.rename(columns={"expire_date": "expiration_date", "facility_zip": "zipcode"})

    # Get boro and limit to NYC
    df = df.loc[df.zipcode.isin(czb.zipcode.tolist()), :]
    df["borough"] = df.zipcode.apply(
        lambda x: czb.loc[czb.zipcode == x, "boro"].tolist()[0]
    )

    # Apply corrections
    for record in corr_dict:
        df.loc[df['facility_location']==record['location'],'facility_location'] = record['correction'].upper()

    # Extract first location
    df["address"] = df["facility_location"].astype(str).apply(clean_address)

    # Parse stretches
    df[["streetname_1", "streetname_2", "streetname_3"]] = df.apply(
            lambda row: pd.Series(find_stretch(row['address'])), axis=1)
    
    # Parse intersections
    df[["streetname_1", "streetname_2"]] = df.apply(
            lambda row: pd.Series(find_intersection(row['address'])), axis=1)

    # Parse house numbers
    df["hnum"] = (
        df["address"]
        .astype(str)
        .apply(get_hnum)
        .apply(lambda x: x.split("/", maxsplit=1)[0] if x != None else x)
    )

    # Parse street names
    df["sname"] = df["address"].astype(str).apply(get_sname)
    df.to_csv('output/pre-geocoding.csv')
    return df

def _geocode(df: pd.DataFrame) -> pd.DataFrame:
    """ 
    Geocode cleaned nysdec state facility permit data using helper/air_geocode()

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

def _output(df):
    """ 
    Output geocoded data to stdout for transfer to postgres
    Parameters: 
    df (DataFrame): Contains input fields along
                    with geosupport fields
    """
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
