CREATE TEMP TABLE tmp as (
    WITH ps_is AS(
        SELECT 
            CASE WHEN a.projected IN ('PK','K','1','2','3','4','5') THEN 'PS'
                WHEN a.projected IN ('6','7','8') THEN 'IS'
            END as level,
            a.*
        FROM sca_e_projections.latest a 
        WHERE a.projected IN ('PK','K','1','2','3','4','5','6','7','8'))
    SELECT
        b.multiplier,
        b.subdistrict,
        a.*
    FROM sca_e_pct.latest b
    JOIN ps_is a 
    ON a.district = b.district
    AND a.level = b.level
);

ALTER TABLE tmp
DROP COLUMN IF EXISTS v;

ALTER TABLE tmp
DROP COLUMN IF EXISTS ogc_fid;

\COPY tmp TO 'output/_sca_e_projections_ps_is.csv' DELIMITER ',' CSV HEADER;