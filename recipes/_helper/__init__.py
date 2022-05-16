from sqlalchemy import create_engine
import os
from datetime import date

EDM_DATA = create_engine(os.environ["EDM_DATA"])
DATE = date.today().strftime("%Y-%m-%d")
