/*
DESCRIPTION:
   1. Load sca_bluebook and lcgms data, filtering out non-CEQR schools
   2. Round enrollment fields to integers
   3. Create geometry from lcgms coordinates
   4. Combine input data
   5. Output records in lcgms but not in bluebook to csv for research
   6. Output records in both sources to PSTDIN for transfer to EDM database
INPUTS: 
    sca_bluebook.latest(
        org_id,
        organization_name,
        bldg_id,
        "bldg_excl.",
        district,
        subdistrict,
        bldg_name,
        org_e,
        "ps_%" as ps_per,
        "ms_%" as ms_per,
        "hs_%" as hs_per,
        charter,
        org_level,
        pc,
        ic,
        hc,
        x,
        y,
        address
    ),
    doe_lcgms."2019_new"(
        location_code,
        location_name,
        managed_by_name,
        location_type_description,
        location_category_description,
        building_code,
        building_name,
        address_line_1,
        borough_block_lot,
        latitude,
        longitude
    )
OUTPUTS:
	TEMP tmp(
        district, 
        subdistrict, 
        borocode,
        bldg_name,
        excluded,
        bldg_id,
        org_id,
        org_level,
        name,
        address,
        pc,
        pe,
        ic,
        ie,
        hc,
        he,
        geom
    ) >> PSTDOUT
*/

CREATE TEMP TABLE tmp AS(
    WITH bluebook_filtered AS
        (SELECT 
            org_id,
            organization_name,
            bldg_id,
            "bldg_excl.",
            district,
            subdistrict,
            bldg_name,
            org_e,
            "ps_%" as ps_per,
            "ms_%" as ms_per,
            "hs_%" as hs_per,
            charter,
            org_level,
            pc,
            ic,
            hc,
            x,
            y,
            address,
            CASE
                WHEN  org_id IN ('X695', 'M645')
                THEN 'Orgid X695 OR M645'
                WHEN org_id IN ('M539', 'M334', 'K686','Q300', 'M012', 'M485')
                THEN 'citywide gifted and talented schools'
                WHEN org_id IN ('X445','K449','K430','M692','X696','Q687','R605','M475')
                THEN 'competitive high schools'
                WHEN organization_name ~* 'Adult'
                    OR organization_name ~* 'pre-k'
                THEN 'organization_name contains Adult OR PREK'
                WHEN organization_name ~* 'ALC'
                    OR organization_name ~* 'ALTERNATIVE LEARNING'
                    OR org_id IN ('M973','Q950') 
                THEN 'organization_name like ALC or ALTERNATIVE LEARNING or Restart org_id'
                WHEN charter IS NOT NULL 
                THEN 'charter IS NOT NULL'
                WHEN org_level IS NULL
                    OR org_level = 'SPED'
                    OR org_level = 'OTHER' 
                THEN 'org_level IS NULL, SPED, or OTHER'
                WHEN org_id IS NULL 
                THEN 'org_id IS NULL'
            END as excluded
        FROM sca_bluebook.latest),
    lcgms_filtered AS 
        (SELECT
            location_code,
            location_name,
            managed_by_name,
            location_type_description,
            location_category_description,
            building_code,
            building_name,
            address_line_1,
            borough_block_lot,
            latitude,
            longitude,
            CASE
                WHEN location_name ~* 'PORTABLE|MINI'
                    AND location_code||borough_block_lot IN
                    (SELECT location_code||borough_block_lot 
                        FROM doe_lcgms.latest 
                        WHERE location_name !~* 'PORTABLE'
                        AND location_name !~* 'MINI')
                THEN 'Not Solo Mini or Portable'
                WHEN location_code IN ('X695', 'M645')
                THEN 'Orgid X695 OR M645'
                WHEN location_name ~* ' AF'
                    OR location_name ~* 'GYM'
                    OR location_name ~* ' FARM '
                THEN 'building_name contains AF or GYM or FARM'
                WHEN location_code IN ('M539', 'M334', 'K686','Q300', 'M012','M485')
                THEN 'citywide gifted and talented schools'
                WHEN location_code IN ('X445','K449','K430','M692','X696','Q687','R605','M475')
                THEN 'competitive high schools'
                WHEN location_type_description = 'Special Education'
                    OR location_type_description = 'Home School'
                THEN 'location_type_description = Special Education or Home School'
                WHEN managed_by_name <> 'DOE'
                THEN 'managed_by_name <> DOE (exclude charter)'       
                WHEN location_category_description IS NULL
                    OR location_category_description = 'Ungraded'
                THEN 'location_category_description is NULL or Ungraded'
            END as excluded
        FROM doe_lcgms."2019_new"  
    )
    SELECT
        b.district, 
        b.subdistrict, 
        LEFT(a.borough_block_lot,1) as borocode,
        a.building_name as bldg_name,
        b."bldg_excl." as excluded,
        a.building_code as bldg_id,
        a.location_code as org_id,
        b.org_level,
        a.location_name as name,
        a.address_line_1 as address,
        floor(b.pc::numeric) as pc,
        ceil(b.org_e::numeric*ROUND((REPLACE(b.ps_per,'%','')::numeric/100),5)) as pe,
        floor(b.ic::numeric) as ic,
        ceil(b.org_e::numeric*ROUND((REPLACE(b.ms_per,'%','')::numeric/100),5)) as ie,
        floor(b.hc::numeric) as hc,
        ceil(b.org_e::numeric*ROUND((REPLACE(b.hs_per,'%','')::numeric/100),5)) as he,
        ST_SetSRID(ST_MakePoint(REPLACE(a.longitude,'NULL', '0')::NUMERIC,REPLACE(a.latitude,'NULL', '0')::NUMERIC),4326) AS geom
    FROM lcgms_filtered a
    LEFT JOIN bluebook_filtered b
    ON a.location_code=b.org_id
    AND a.building_code = b.bldg_id
    WHERE a.excluded IS NULL 
    AND b.excluded IS NULL
);

\COPY (SELECT * FROM tmp WHERE district IS NULL AND subdistrict IS NULL) TO 'output/lcgms_not_in_bluebook.csv' DELIMITER ',' CSV HEADER;
\COPY (SELECT * FROM tmp WHERE district IS NOT NULL AND subdistrict IS NOT NULL) TO PSTDOUT DELIMITER ',' CSV HEADER;
