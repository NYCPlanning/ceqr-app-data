from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
import os
from datetime import date

DATE = date.today().strftime("%Y-%m-%d")

def create_edm_date_engine() -> Engine:
    return create_engine(os.environ["EDM_DATA"], isolation_level="AUTOCOMMIT")

def execute_sql_query(statement: str) -> None:
    edm_data_engine = create_edm_date_engine()
    with edm_data_engine.connect() as sql_conn:
        sql_conn.execute(statement=text(statement))
