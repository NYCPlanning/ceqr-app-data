CREATE TEMP TABLE tmp as (
    SELECT CASE 
                WHEN a.district::int BETWEEN 1 AND 6 THEN 'Manhattan'
                WHEN a.district::int BETWEEN 7 AND 12 THEN 'Bronx'
                WHEN a.district::int BETWEEN 13 AND 23 
                    OR a.district::int = 32  THEN 'Brooklyn'
                WHEN a.district::int BETWEEN 24 AND 30 THEN 'Queens'  
                WHEN a.district::int = 31  THEN 'Staten Island'
            END as borough,
            a.*
    FROM sca_e_projections.latest a 
    WHERE a.projected IN ('9','10','11','12')
);

ALTER TABLE tmp
DROP COLUMN IF EXISTS v;

ALTER TABLE tmp
DROP COLUMN IF EXISTS ogc_fid;

\COPY tmp TO 'output/_sca_e_projections_by_boro.csv' DELIMITER ',' CSV HEADER;