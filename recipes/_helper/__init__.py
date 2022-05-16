from sqlalchemy import create_engine
import os
from datetime import date


# CEQR_DATA = create_engine(os.environ["CEQR_DATA"])
print(f"EDM_DATA is f{os.environ['EDM_DATA']}")
print(f"DO S3 endpoint is f{os.environ['AWS_S3_ENDPOINT']}")
EDM_DATA = create_engine(os.environ["EDM_DATA"])
DATE = date.today().strftime("%Y-%m-%d")
