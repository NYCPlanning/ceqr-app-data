import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, geocode
#from _helper.geo import get_hnum, get_sname, clean_house, clean_street, geocode
from multiprocessing import Pool, cpu_count


def _import() -> pd.DataFrame:
    """ 
    Import _ceqr_school_buildings

    Returns: 
    df (DataFrame): Contains combined lcgms and bluebook data
                    with hnum and sname parsed
                    from primary_address
    """
    df = pd.read_csv('output/_ceqr_school_buildings.csv')
    
    # Parse house numbers
    df["hnum"] = (
        df["primary_address"]
        .astype(str)
        .apply(get_hnum)
        .apply(lambda x: x.split("/", maxsplit=1)[0] if x != None else x)
    )

    # Parse street names
    df["sname"] = df["primary_address"].astype(str).apply(get_sname)

    # Parse borough
    df["borough"] = df["borough_block_lot"].astype(str).str[0]

    return df
    
def _geocode(df: pd.DataFrame) -> pd.DataFrame:
    """ 
    Geocode parsed school buildings data

    Parameters: 
    df (DataFrame): Contains combined lcgms and bluebook data
                    with hnum and sname parsed
                    from primary_address
    Returns:
    df (DataFrame): Contains input fields along
                    with geosupport fields
    """
    records = df.to_dict('records')
    del df

    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, 10000)

    df = pd.DataFrame(it)
    df['geo_longitude'] = pd.to_numeric(df['geo_longitude'], errors='coerce')
    df['geo_latitude'] = pd.to_numeric(df['geo_latitude'], errors='coerce')

    return df

def _output(df):
    """ 
    Output geocoded data. 
    
    Parameters: 
    df (DataFrame): Contains input fields along
                    with geosupport fields
    """
    cols = [
        "district",
        "subdistrict",
        "borocode",
        "excluded",
        "bldg_id",
        "org_id",
        "org_level",
        "name",
        "address",
        "pc",
        "pe",
        "ic",
        "ie",
        "hc",
        "he",
        "geo_xy_coord",
        "geo_x_coord",
        "geo_y_coord",
        "geo_from_x_coord",
        "geo_from_y_coord",
        "geo_to_x_coord",
        "geo_to_y_coord",
        "geo_function",
        "geo_grc",
        "geo_grc2",
        "geo_reason_code",
        "geo_message"
    ]
    df[cols].to_csv('output/all_capacity_projects.csv')

    # Remove special ed cases
    df_filtered = df[(df['district']!='75')&(df.org_level!='PK')&(df.org_level!='3K')]
    df_filtered[cols].to_csv(sys.stdout, sep='|', index=False)

if __name__ == "__main__":
    df = _import()
    df = _geocode(df)
    _output(df)