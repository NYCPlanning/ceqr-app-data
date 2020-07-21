CREATE TEMP TABLE tmp (
    district character varying,
    borough character varying,
    year integer,
    hs integer
);

\COPY tmp FROM PSTDIN DELIMITER '|' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    year,
    borough,
    SUM(hs) as hs
INTO :NAME.:"VERSION"
FROM tmp
GROUP BY year, borough;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :"VERSION" as v, * 
    FROM :NAME.:"VERSION"
);