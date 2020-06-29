CREATE TEMP TABLE nysdec_title_v_facility_permits (
    facility_name text,
    permit_id text,
    url_to_permit_text text,
    facility_location text,
    address text,
    housenum text,
    streetname text,
    streetname_1 text,
    streetname_2 text,
    facility_city text,
    facility_state text,
    borough text,
    zipcode text,
    issue_date date,
    expiration_date date,
    location text,
    geo_housenum text,
    geo_streetname text,
    geo_address text,
    geo_bbl bigint,
    geo_bin text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_x_coord double precision,
    geo_y_coord double precision,
    geo_function text
);


\COPY nysdec_title_v_facility_permits FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT 
    *,
    ST_SetSRID(ST_MakePoint(geo_longitude,geo_latitude),4326)::geometry(Point,4326) as geom
INTO :NAME.:"VERSION"
FROM nysdec_title_v_facility_permits;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);