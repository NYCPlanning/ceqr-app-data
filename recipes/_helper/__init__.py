from sqlalchemy import create_engine
import os
from datetime import date

edm_data_path = os.environ["EDM_DATA"]
print(f"path loaded from secrets: {edm_data_path}")
EDM_DATA = create_engine(os.environ["EDM_DATA"])
CEQR_DATA = create_engine(os.environ["CEQR_DATA"])
DATE = date.today().strftime("%Y-%m-%d")
