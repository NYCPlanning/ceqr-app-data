from sqlalchemy import create_engine
import os
from datetime import date


# CEQR_DATA = create_engine(os.environ["CEQR_DATA"])
print(f"environmental variables are f{os.environ}")
EDM_DATA = create_engine(os.environ["EDM_DATA"])
DATE = date.today().strftime("%Y-%m-%d")
