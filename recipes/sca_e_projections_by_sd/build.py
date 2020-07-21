import sys
import os

sys.path.insert(0, "..")
import pandas as pd
import numpy as np
import re


if __name__ == "__main__":
    df = pd.read_csv('output/_sca_e_projections_ps_is.csv')
    
    # Change school_year field type to integer if necessary
    for school_year in df.columns[4:]:
        try:
            df[school_year] = df[school_year].str.replace(",","").astype(int)
        except:
            pass


    # Unpivot the table
    df_unpivot = df.melt(id_vars=['district', 'subdistrict','level','multiplier','projected'], 
                                                    var_name='school_year', 
                                                    value_name='e')
    df_unpivot.to_csv('output/unpivoted.csv', index=False)
    df_unpivot.to_csv(sys.stdout, sep='|', index=False)