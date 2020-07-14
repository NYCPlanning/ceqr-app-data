CREATE TEMP TABLE tmp as (
    WITH draft as (
        SELECT 
            *, 
            municipality_desc AS borough, 
            wkb_geometry AS geom
        FROM nysdot_functional_class.latest c
        WHERE wkb_geometry IS NOT NULL 
        AND c.ogc_fid IN (
            SELECT a.ogc_fid FROM
            nysdot_functional_class.latest a, (
                SELECT ST_Union(wkb_geometry) As wkb_geometry
                FROM dcp_boroboundaries_wi.latest
            ) b
            WHERE ST_Contains(b.wkb_geometry, a.wkb_geometry)
            OR ST_Intersects(b.wkb_geometry, a.wkb_geometry)
        )
    ) 
    SELECT 
        a.objectid,
        a.route_no,
        a.func_class,
        a.segment_name,
        a.unique_id,
        a.roadway_type,
        a.co_rd_no,
        a.access_control,
        a.bridge_feature_number,
        a.hpms_sample_id,
        a.jurisdiction,
        a.last_actual_cntyr,
        a.median_type,
        a.mpo,
        a.municipality_type,
        a.borough,
        a.owning_juris,
        a.ramp_dest_co_order,
        a.ramp_orig_co_order,
        a.shoulder_type,
        a.strahnet,
        a.surface_type,
        a.tandem_truck,
        a.toll,
        a.urban_area_code,
        a.owned_by_muni_type,
        a.from_date,
        a.to_date,
        a.locerror,
        a."shape.stlength()",
        a.signing,
        a.geom
    FROM draft a
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;
