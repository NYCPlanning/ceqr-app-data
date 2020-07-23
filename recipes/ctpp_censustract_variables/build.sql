/*
DESCRIPTION: 
    1. recode transit modes
        1. translate `lineno` to human readable modes
        2. clean value and moe
        3. filter and select records in NYC by fips codes
        4. for each geoid, aggregate values, moes for 
        different modes into jsonb objects 
        
        RECODE (
            geoid text,
            _val jsonb,
            _moe jsonb
        )
    
    2. Calculate MOE for combination variables (square root of sum of sqaures of moes)
    3. Calculate VALUES for  combination variables (sum of values)
    4. Merge into final output

INPUT:
    ctpp_mode_split_ny (
        geoid text,
        lineno text,
        est text,
        moe text
    )

OUTPUT: 
    TEMP tmp (
        geoid character varying,
        value integer,
        moe integer,
        variable character varying
    )
*/
CREATE TEMP TABLE RECODE as (
    SELECT
        geoid, 
        jsonb_object_agg(mode, value) as _val, 
        jsonb_object_agg(mode, moe) as _moe
    FROM (
        SELECT 
            LEFT(split_part(geoid, 'US', 2),11) as geoid,
            lineno AS variable,
            (CASE
                WHEN lineno = '1' THEN 'trans_total'
                WHEN lineno = '2' THEN 'trans_auto_solo'
                WHEN lineno = '3' THEN 'trans_auto_2'
                WHEN lineno = '4' THEN 'trans_auto_3'
                WHEN lineno = '5' THEN 'trans_auto_4'
                WHEN lineno = '6' THEN 'trans_auto_5_or_6'
                WHEN lineno = '7' THEN 'trans_auto_7_or_more'
                WHEN lineno = '8' THEN 'trans_public_bus'
                WHEN lineno = '9' THEN 'trans_public_streetcar'
                WHEN lineno = '10' THEN 'trans_public_subway'
                WHEN lineno = '11' THEN 'trans_public_rail'
                WHEN lineno = '12' THEN 'trans_public_ferry'
                WHEN lineno = '13' THEN 'trans_bicycle'
                WHEN lineno = '14' THEN 'trans_walk'
                WHEN lineno = '15' THEN 'trans_taxi'
                WHEN lineno = '16' THEN 'trans_motorcycle'
                WHEN lineno = '17' THEN 'trans_other'
                WHEN lineno = '18' THEN 'trans_home'
            END) AS mode,
            REPLACE(est, ',', '') AS value,
            REPLACE(replace(moe, ',' ,''), '+/-', '') as moe
        FROM ctpp_mode_split_ny."2012_2016"
        WHERE LEFT(split_part(geoid, 'US', 2),5) in 
            ('36061', '36047', '36005', '36081', '36085')
            AND LENGTH(geoid) = 18
    ) a
    GROUP BY geoid
);

CREATE TEMP TABLE tmp as (
   WITH 
    _MOE AS (
        SELECT
            a.geoid,
            b.*, 
            SQRT(
                COALESCE(POWER(b.trans_auto_2, 2), 0) +
                COALESCE(POWER(b.trans_auto_3, 2), 0) +
                COALESCE(POWER(b.trans_auto_4, 2), 0) +
                COALESCE(POWER(b.trans_auto_5_or_6, 2), 0) +
                COALESCE(POWER(b.trans_auto_7_or_more, 2), 0)
            ) as trans_auto_carpool_total,

            SQRT(
                COALESCE(POWER(b.trans_auto_solo, 2), 0) +
                COALESCE(POWER(b.trans_auto_2, 2), 0) +
                COALESCE(POWER(b.trans_auto_3, 2), 0) +
                COALESCE(POWER(b.trans_auto_4, 2), 0) +
                COALESCE(POWER(b.trans_auto_5_or_6, 2), 0) +
                COALESCE(POWER(b.trans_auto_7_or_more, 2), 0)
            ) as trans_auto_total,

            SQRT(
                COALESCE(POWER(b.trans_public_bus, 2), 0) +
                COALESCE(POWER(b.trans_public_streetcar, 2), 0) +
                COALESCE(POWER(b.trans_public_subway, 2), 0) +
                COALESCE(POWER(b.trans_public_rail, 2), 0) +
                COALESCE(POWER(b.trans_public_ferry, 2), 0)
            ) as trans_public_total
        FROM RECODE a, 
            -- pivot jsonb to columns (key -> field name, value -> field value), 
            -- this step is needed because not all tracts have all modes of travel
            -- NULLs will be filled with 0s and calculated as 0s
            this step will allow us to 
            jsonb_to_record(_moe) as  b(
                trans_total numeric, trans_auto_solo numeric,
                trans_auto_2 numeric, trans_auto_3 numeric,
                trans_auto_4 numeric, trans_auto_5_or_6 numeric,
                trans_auto_7_or_more numeric, trans_public_bus numeric,
                trans_public_streetcar numeric, trans_public_subway numeric,
                trans_public_rail numeric, trans_public_ferry numeric,
                trans_bicycle numeric, trans_walk numeric, trans_taxi numeric,
                trans_motorcycle numeric, trans_other numeric, trans_home numeric)
    ),
    MOE AS (
        SELECT
            a.geoid,
            b.key as variable,
            coalesce(b.value::numeric, 0)::integer as moe
        FROM (
            SELECT 
                geoid, 
                row_to_json(row) as _col
            FROM (select * from _MOE) as row) a, 
            json_each_text(_col) b
        WHERE b.key != 'geoid'
    ), 
    _VAL AS (
        SELECT 
            a.geoid,
            b.*,
            
            COALESCE(b.trans_auto_2, 0) +
            COALESCE(b.trans_auto_3, 0) +
            COALESCE(b.trans_auto_4, 0) +
            COALESCE(b.trans_auto_5_or_6, 0) +
            COALESCE(b.trans_auto_7_or_more, 0) 
            as trans_auto_carpool_total, 

            COALESCE(b.trans_auto_solo, 0) +
            COALESCE(b.trans_auto_2, 0) +
            COALESCE(b.trans_auto_3, 0) +
            COALESCE(b.trans_auto_4, 0) +
            COALESCE(b.trans_auto_5_or_6, 0) +
            COALESCE(b.trans_auto_7_or_more, 0) 
            as trans_auto_total,  

            COALESCE(b.trans_public_bus, 0) +
            COALESCE(b.trans_public_streetcar, 0) +
            COALESCE(b.trans_public_subway, 0) +
            COALESCE(b.trans_public_rail, 0) +
            COALESCE(b.trans_public_ferry, 0) 
            as trans_public_total

        FROM RECODE a, 
            -- pivot jsonb to columns (key -> field name, value -> field value), 
            -- this step is needed because not all tracts have all modes of travel
            jsonb_to_record(_val) as b(
                trans_total numeric, trans_auto_solo numeric,
                trans_auto_2 numeric, trans_auto_3 numeric,
                trans_auto_4 numeric, trans_auto_5_or_6 numeric,
                trans_auto_7_or_more numeric, trans_public_bus numeric,
                trans_public_streetcar numeric, trans_public_subway numeric,
                trans_public_rail numeric, trans_public_ferry numeric,
                trans_bicycle numeric, trans_walk numeric, trans_taxi numeric,
                trans_motorcycle numeric, trans_other numeric, trans_home numeric)
    ), 
    VAL AS (
        SELECT
            a.geoid,
            b.key as variable,
            coalesce(b.value::numeric, 0)::integer as "value"
        FROM (
            SELECT 
                geoid, 
                row_to_json(row) as _col
            FROM (select * from _VAL) as row) a, 
            json_each_text(_col) b
        WHERE b.key != 'geoid'
    )
    SELECT
        a.geoid, 
        a.value::numeric::integer as value,
        b.moe::numeric::integer as moe,
        a.variable
    FROM VAL a
    FULL OUTER JOIN MOE b
    ON a.geoid = b.geoid 
    AND a.variable = b.variable
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;