/*
DESCRIPTION:
    This table has the census tract geoid and tract 
    multipolygon centroid of three states NY, CT and NJ
    
INPUT:
    uscensus_ct_shp (
        geoid,
        wkb_geometry geometry(MultiPolygon,4326)
    )
    
    uscensus_ny_shp (
        geoid,
        wkb_geometry geometry(MultiPolygon,4326)
    )
    
    uscensus_nj_shp (
        geoid,
        wkb_geometry geometry(MultiPolygon,4326)
    )
    
OUTPUT:
    TEMP tmp (
        goid character varying,
        centroid geometry(Point,4326) 
    )
*/
CREATE TEMP TABLE tmp as (
    SELECT 
        geoid, 
        st_centroid(wkb_geometry) as centroid
    FROM (
        (select * FROM uscensus_ct_shp."2019/09/17")
        UNION 
        (select * FROM uscensus_ny_shp."2019/09/17")
        UNION
        (select * FROM uscensus_nj_shp."2019/09/17")
    ) a
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;