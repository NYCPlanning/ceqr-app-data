CREATE TEMP TABLE tmp (
    year text,
    borough character varying,
    hs bigint
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