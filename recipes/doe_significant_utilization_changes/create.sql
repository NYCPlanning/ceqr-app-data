CREATE TEMP TABLE tmp (
    bldg_id character varying,
    org_id character varying,
    bldg_id_additional character varying,
    title character varying,
    at_scale_year character varying,
    url character varying,
    at_scale_enroll integer,
    vote_date character varying
);

\COPY tmp FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT *
INTO :NAME.:"VERSION"
FROM tmp;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);