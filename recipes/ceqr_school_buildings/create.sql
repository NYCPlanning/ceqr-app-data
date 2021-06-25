/*
DESCRIPTION:
   Import ceqr_school_buildings to EDM database using PSTDIN
INPUTS: 
    PSTDIN >> 
    TEMP tmp(
        district integer,
        subdistrict integer,
        borocode integer,
        bldg_name character varying,
        excluded boolean,
        bldg_id character varying,
        org_id character varying,
        org_level character varying,
        name character varying,
        address character varying,
        pc integer,
        pe integer,
        ic integer,
        ie integer,
        hc integer,
        he integer,
        geom geometry
    )
OUTPUTS:
	ceqr_school_buildings.latest(
        Same schema as input
    )
*/
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
    geo_xy_coord text,
    geo_x_coord double precision,
    geo_y_coord double precision,
    geo_from_x_coord double precision,
    geo_from_y_coord double precision,
    geo_to_x_coord double precision,
    geo_to_y_coord double precision,
    geo_function text,
    geo_grc text,
    geo_grc2 text,
    geo_reason_code text,
    geo_message text
);

\COPY tmp FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    district,
    subdistrict,
    borocode,
    bldg_name,
    excluded,
    bldg_id,
    org_id,
    org_level,
    "name",
    "address",
    pc,
    pe,
    ic,
    ie,
    hc,
    he,
    (CASE 
        -- Intersections: Create  geometry from x_coord and y_coord
        WHEN geo_function = 'Intersection'
        THEN ST_TRANSFORM(ST_SetSRID(ST_MakePoint(geo_x_coord,geo_y_coord),2263),4326)
        -- Segments: Find the middle of the segment by creating a line from to/from coords
        WHEN geo_function = 'Stretch'
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
FROM tmp;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);