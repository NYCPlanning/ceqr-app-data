CREATE TEMP TABLE sca_capacity_projects (
    uid text
    name text
    org_level text
    district text
    capacity bigint
    pct_ps double precision
    pct_is double precision
    pct_hs double precision
    guessed_pct boolean
    start_date date
    capital_plan text
    borough text
    address text
    geo_xy_coord text
    geo_x_coord double precision
    geo_y_coord double precision
    geo_from_x_coord double precision
    geo_from_y_coord double precision
    geo_to_x_coord double precision
    geo_to_y_coord double precision
    geo_function text
    geom geometry
    geo_grc text
    geo_grc2 text
    geo_reason_code text
    geo_message text
);


\COPY sca_capacity_projects FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    *,
    (CASE WHEN geo_function = 'Intersection'
        THEN ST_TRANSFORM(ST_SetSRID(ST_MakePoint(geo_x_coord,geo_y_coord),2263),4326)
        ELSE ST_SetSRID(ST_MakePoint(geo_longitude,geo_latitude),4326)
    END)::geometry(Point,4326) as geom
INTO :NAME.:"VERSION"
FROM sca_capacity_projects;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);