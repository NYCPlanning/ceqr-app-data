CREATE TEMP TABLE tmp as (
    SELECT 
        name,
        address,
        link,
        wkb_geometry as geom
    FROM tunnel_ventilation_towers.latest
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;