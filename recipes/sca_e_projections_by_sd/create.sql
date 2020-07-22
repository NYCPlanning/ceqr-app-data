CREATE TEMP TABLE tmp (
    school_year text,
    district character varying,
    subdistrict character varying,
    ps numeric,
    "is" numeric
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