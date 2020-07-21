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