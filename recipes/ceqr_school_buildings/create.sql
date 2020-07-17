CREATE TEMP TABLE tmp (
    district integer,
    subdistrict integer,
    borocode integer,
    bldg_name character varying,
    excluded boolean,
    bldg_id character varying,
    org_id character varying,
    org_level character varying,
    "name" character varying,
    "address" character varying,
    pc integer,
    pe integer,
    ic integer,
    ie integer,
    hc integer,
    he integer,
    geom geometry(Point,4326)
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