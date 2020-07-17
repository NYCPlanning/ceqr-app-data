CREATE TEMP TABLE tmp (
    content text,
    icon text,
    id text,
    latitude double precision,
    longitude double precision,
    title text,
    url text
)


\COPY tmp FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    *,
    ST_SetSRID(ST_MakePoint(longitude,latitude),4326)::geometry(Point,4326) as geom
INTO :NAME.:"VERSION"
FROM tmp;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);