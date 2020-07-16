import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re
from _helper.geo import get_hnum, get_sname, clean_house, clean_street, schools_geocode as geocode
from multiprocessing import Pool, cpu_count


def _import() -> pd.DataFrame:
    df = pd.read_csv('output/_sca_capacity_projects.csv')
    
    # Import csv to replace invalid addresses with manual corrections
    cor_add_dict = pd.read_csv('../_data/sca_capacity_address_cor.csv', dtype=str, engine="c").to_dict('records')
    for record in cor_add_dict:
        df.loc[df['name']==record['school'],'address'] = record['address'].upper()

    # Import csv to replace org_levels with manual corrections
    cor_org_dict = pd.read_csv('../_data/sca_capacity_org_level_cor.csv', dtype=str, engine="c").to_dict('records')
    for record in cor_org_dict:
        df.loc[df['name']==record['school'],'org_level'] = record['org_level']

    # Clean inputs for geocoding
    df['hnum'] = df.address.apply(get_hnum).apply(lambda x: clean_house(x))
    df['sname'] = df.address.apply(get_sname).apply(lambda x: clean_street(x))

    df.to_csv('output/_sca_capacity_project_corrected.csv')
    return df
    
def _geocode(df: pd.DataFrame) -> pd.DataFrame:
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
    cols = [
        "uid",
        "name",
        "org_level",
        "district",
        "capacity",
        "pct_ps",
        "pct_is",
        "pct_hs",
        "guessed_pct",
        "start_date",
        "capital_plan",
        "borough",
        "address",
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