CREATE TEMP TABLE tmp as (
    WITH 
    PROCESSED AS (
        SELECT
            geoid,
            jsonb_build_object(
                'trans_auto_carpool_total',
                    COALESCE((_val ->> 'trans_auto_2')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_3')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_4')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_5_or_6')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_7_or_more')::numeric, 0), 
                    
                'trans_auto_total',
                    COALESCE((_val ->> 'trans_auto_solo')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_2')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_3')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_4')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_5_or_6')::numeric, 0) +
                    COALESCE((_val ->> 'trans_auto_7_or_more')::numeric, 0),
                    
                'trans_public_total',
                    COALESCE((_val ->> 'trans_public_bus')::numeric, 0) +
                    COALESCE((_val ->> 'trans_public_streetcar')::numeric, 0) +
                    COALESCE((_val ->> 'trans_public_subway')::numeric, 0) +
                    COALESCE((_val ->> 'trans_public_rail')::numeric, 0) +
                    COALESCE((_val ->> 'trans_public_ferry')::numeric, 0)
            ) || _val as _val,
            
            jsonb_build_object(
                'trans_auto_carpool_total',
                    SQRT(
                        COALESCE(POWER((_val ->> 'trans_auto_2')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_3')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_4')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_5_or_6')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_7_or_more')::numeric, 2), 0)
                    ),
                
                'trans_auto_total',
                    SQRT(
                        COALESCE(POWER((_val ->> 'trans_auto_solo')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_2')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_3')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_4')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_5_or_6')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_auto_7_or_more')::numeric, 2), 0)
                    ),
                    
                'trans_public_total',
                    SQRT(
                        COALESCE(POWER((_val ->> 'trans_public_bus')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_public_streetcar')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_public_subway')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_public_rail')::numeric, 2), 0) +
                        COALESCE(POWER((_val ->> 'trans_public_ferry')::numeric, 2), 0)
                    )
            ) || _moe as _moe
        FROM(
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
        ) a
    ), 
    VALUES as (
        SELECT geoid, b.key as variable, b.value as value
        FROM PROCESSED, jsonb_each_text(_val) as b
    ),
    MOES as (
        SELECT geoid, b.key as variable, b.value as moe
        FROM PROCESSED, jsonb_each_text(_moe) as b
    )
    SELECT
        a.geoid, 
        a.value::numeric::integer as value,
        b.moe::numeric::integer as moe,
        a.variable
    FROM VALUES a
    FULL OUTER JOIN MOES b
    ON a.geoid = b.geoid 
    AND a.variable = b.variable
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;