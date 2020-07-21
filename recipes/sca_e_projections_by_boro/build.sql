CREATE TEMP TABLE tmp as (
    SELECT a.*,
            CASE 
                WHEN a.district::int BETWEEN 1 AND 6 THEN 'Manhattan'
                WHEN a.district::int BETWEEN 7 AND 12 THEN 'Bronx'
                WHEN a.district::int BETWEEN 13 AND 23 
                    OR a.district::int = 32  THEN 'Brooklyn'
                WHEN a.district::int BETWEEN 24 AND 30 THEN 'Queens'  
                WHEN a.district::int = 31  THEN 'Staten Island'
            END as borough
    FROM sca_e_projections a 
    WHERE a.projected IN ('9','10','11','12')
);

\COPY tmp TO 'output/_sca_e_projections_by_boro.csv' DELIMITER ',' CSV HEADER;