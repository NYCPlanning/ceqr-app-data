CREATE TEMP TABLE tmp (
    district character varying,
    borough character varying,
    year character varying,
    hs integer
);

\COPY tmp FROM PSTDIN DELIMITER '|' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    LEFT(year, 4) as year,
    borough,
    SUM(hs) as hs
INTO :NAME.:"VERSION"
FROM tmp
GROUP BY year, borough
ORDER BY borough, year;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :"VERSION" as v, * 
    FROM :NAME.:"VERSION"
);