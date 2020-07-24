CREATE TEMP TABLE dep_cats_permits (
    requestid text,
    applicationid text,
    requesttype text,
    ownername text,
    expiration_date date,
    make text,
    model text,
    burnermake text,
    burnermodel text,
    primaryfuel text,
    secondaryfuel text,
    quantity text,
    issue_date date,
    status text,
    premisename text,
    housenum text,
    streetname text,
    address text,
    borough text,
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

\COPY dep_cats_permits FROM PSTDIN DELIMITER '|' CSV HEADER;

DROP TABLE IF EXISTS dep_cats_permits.:"VERSION" CASCADE;
SELECT 
    *,
    ST_SetSRID(ST_MakePoint(geo_longitude,geo_latitude),4326) as geom
INTO dep_cats_permits.:"VERSION"
FROM dep_cats_permits
WHERE TRIM(status) != 'CANCELLED'
AND LEFT(applicationid, 1) != 'G'
AND (LEFT(applicationid, 1) != 'C'
    OR (requesttype != 'REGISTRATION'
        AND requesttype != 'REGISTRATION INSPECTION'
        AND requesttype != 'BOILER REGISTRATION II'))
AND (LEFT(applicationid, 2) != 'CA'
    OR requesttype != 'WORK PERMIT'
    OR TRIM(status) != 'EXPIRED');

DROP VIEW IF EXISTS dep_cats_permits.latest;
CREATE VIEW dep_cats_permits.latest AS (
    SELECT :'VERSION' as v, * 
    FROM dep_cats_permits.:"VERSION"
);