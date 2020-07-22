/*
DESCRIPTION:
    1. Unpivot sca_e_projections so that we get a table like the following: 

        district |  projected  | year |  hs   
       ----------+-------------+------+-------
        ...      | ...         | ...  |   ...
        1        | PK          | 2026 |   XXX
        2        | PK          | 2027 |   XXX
        4        | PK          | 2028 |   XXX
        ...      | ...         | ...  |   ...
        2        | K           | 2018 |   XXX
        1        | K           | 2019 |   XXX
        3        | K           | 2020 |   XXX
        ...      | ...         | ...  |   ...

    2. Assign Borough to school districts: 
        MN: 1 ~ 6
        BX: 7 ~ 12
        BK: 13 ~ 23 and 32
        QN: 24 ~ 30
        SI: 31
    
    3. Aggregate over borough and school year by summing over hs

INPUT:
    sca_e_projections.:"VERSION" (
        district character varying,
        projected character varying,
        "2018_19" character varying,
        "2019_20" character varying,
        "2020_21" character varying,
        "2021_22" character varying,
        "2022_23" character varying,
        "2023_24" character varying,
        "2024_25" character varying,
        "2025_26" character varying,
        "2026_27" character varying,
        "2027_28" character varying,
        "2028_29" character varying
    )

OUTPUT:

    TEMP tmp (
        year text,
        borough character varying,
        hs bigint
    )

*/
CREATE TEMP TABLE tmp as (
    WITH 
    unpivot as (
        select 
            _col ->> 'district' as district, 
            _col ->> 'projected' as projected,
            LEFT(b.key, 4) as year, 
            replace(b.value, ',', '')::integer as hs
        FROM (
            select row_to_json(row) as _col 
            from (select * from sca_e_projections."2019") row) a , 
            json_each_text(_col) as b
        where b.key not in ('ogc_fid', 'district', 'projected')
    ),
    BOROUGH as (
        SELECT *,
        (CASE 
            WHEN district::int BETWEEN 1 AND 6 
                THEN 'Manhattan'
            WHEN district::int BETWEEN 7 AND 12 
                THEN 'Bronx'
            WHEN district::int BETWEEN 13 AND 23 
                OR district::int = 32  
                THEN 'Brooklyn'
            WHEN district::int BETWEEN 24 AND 30 
                THEN 'Queens'  
            WHEN district::int = 31
                THEN 'Staten Island'
        END) as borough
        FROM unpivot
    )
    SELECT 
        LEFT(year, 4) as year,
        borough,
        SUM(hs) as hs
    FROM BOROUGH 
    WHERE projected IN ('9','10','11','12')
    GROUP BY year, borough
    ORDER BY year, borough
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;