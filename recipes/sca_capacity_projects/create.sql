CREATE TEMP TABLE sca_capacity_projects (
    uid text,
    name text,
    org_level text,
    district text,
    capacity bigint,
    pct_ps double precision,
    pct_is double precision,
    pct_hs double precision,
    guessed_pct boolean,
    start_date date,
    capital_plan text,
    borough text,
    address text,
    geo_xy_coord text,
    geo_x_coord double precision,
    geo_y_coord double precision,
    geo_from_x_coord double precision,
    geo_from_y_coord double precision,
    geo_to_x_coord double precision,
    geo_to_y_coord double precision,
    geo_function text,
    geom geometry,
    geo_grc text,
    geo_grc2 text,
    geo_reason_code text,
    geo_message text
);


\COPY sca_capacity_projects FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    uid,
    name,
    org_level,
    district,
    capacity,
    pct_ps,
    pct_is,
    pct_hs,
    guessed_pct,
    start_date,
    capital_plan,
    borough,
    address,
    geo_function,
    (CASE 
        -- Intersections: Create  geometry from x_coord and y_coord
        WHEN geo_function = 'Intersection'
        THEN ST_TRANSFORM(ST_SetSRID(ST_MakePoint(geo_x_coord,geo_y_coord),2263),4326)
        -- Segments: Find the middle of the segment by creating a line from to/from coords
        WHEN geo_function = 'Segment'
        THEN ST_centroid(ST_MakeLine(
                ST_TRANSFORM(ST_SetSRID(
                    ST_MakePoint(geo_from_x_coord::NUMERIC, geo_from_y_coord::NUMERIC),2263),4326),
                ST_TRANSFORM(ST_SetSRID(
                    ST_MakePoint(geo_to_x_coord::NUMERIC, geo_to_y_coord::NUMERIC),2263),4326)))
        -- Address points: Create geometry from xy_coord
        WHEN geo_function IN ('1B','1E') 
        THEN ST_TRANSFORM(ST_SetSRID(ST_MakePoint(LEFT(geo_xy_coord, 7)::DOUBLE PRECISION,
                                            RIGHT(geo_xy_coord, 7)::DOUBLE PRECISION),2263),4326)
        ELSE NULL
    END)::geometry(Point,4326) as geom
INTO :NAME.:"VERSION"
FROM sca_capacity_projects;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);