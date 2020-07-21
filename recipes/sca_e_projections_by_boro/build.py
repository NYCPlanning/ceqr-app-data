import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re


if __name__ == "__main__":
    df = pd.read_csv('output/_sca_e_projections_by_boro.csv')
    
    # Change school_year field type to integer if necessary
    for school_year in df.columns[3:]:
        try:
            df[school_year] = df[school_year].str.replace(",","").astype(int)
        except:
            pass


    # Unpivot the table
    df_unpivot = df.drop(columns=['projected']).melt(id_vars=['district', 'borough'], 
                                                    var_name='school_year', 
                                                    value_name='hs')
    df_unpivot.to_csv(sys.stdout, sep='|', index=False)