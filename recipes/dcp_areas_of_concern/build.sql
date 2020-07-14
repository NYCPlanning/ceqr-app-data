CREATE TEMP TABLE tmp as (
    SELECT 
        name,
        wkb_geometry as geom
    FROM dcp_areas_of_concern.latest
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;