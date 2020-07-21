import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re


if __name__ == "__main__":
    df = pd.read_csv('../output/_sca_e_projections_by_boro.csv')

     # Change school_year field type to integer
    for school_year in df.columns[2:]:
        df[school_year] = df[school_year].str.replace(",","").astype(int)

    # Reformat the table by melting and groupint by district
    df_unpivot = df[df.projected.isin(hs_)].drop(columns=['projected'])\
                                                        .groupby('district')\
                                                        .sum().reset_index()\
                                                        .melt(id_vars=['district', 'borough'], var_name='school_year', value_name='hs')
    df_unpivot.to_csv(sys.stdout, sep='|', index=False)