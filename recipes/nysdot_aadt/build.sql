CREATE TEMP TABLE tmp as (
    SELECT 
        enddesc,
        muni,
        tdv_route,
        aadt_year,
        data_type,
        vol_txt,
        class_txt,
        speed_txt,
        vol_tdv,
        class_tdv,
        speed_tdv,
        "shape.stlength()",
        rc_id,
        loc_error,
        objectid,
        aadt,
        objectid_1,
        ccst,
        begdesc,
        fc,
        perc_truck,
        count_type,
        su_aadt,
        cu_aadt,
        countyr,
        aadt_last_,
        gis_id,
        firstofbeg,
        lastofend_,
        wkb_geometry as geom
    FROM nysdot_aadt.latest
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;