CREATE TEMP TABLE tmp as (
    WITH 
    UNPIVOT as (
        select 
            a._col ->> 'district' as district, 
            a._col ->> 'projected' as projected,
            LEFT(b.key, 4) as school_year, 
            (CASE WHEN a._col ->> 'projected' in 
                    ('PK','K','1','2','3','4','5','6') 
                THEN replace(b.value, ',', '')::integer 
            END) as "ps",
            (CASE WHEN a._col ->> 'projected' in ('7','8') 
                THEN replace(b.value, ',', '')::integer 
            END) as "is"
        FROM (
            select row_to_json(row) as _col 
            from (select * from sca_e_projections."2019") row) a , 
            json_each_text(_col) as b
        where b.key not in ('ogc_fid', 'district', 'projected')
    ),
    MULTIPLY as (
        SELECT
            a.district, 
            a.school_year,
            a.projected,
            a."is"* b.multiplier::numeric as "is",
            a."ps"* b.multiplier::numeric as "ps",
            b.subdistrict
        FROM UNPIVOT a
        FULL OUTER JOIN sca_e_pct."2019" b
        ON a.district = b.district
        WHERE projected IN 
            ('PK','K','1','2','3',
            '4','5','6','7','8')
    )
    SELECT
        school_year,
        district,
        subdistrict,
        sum("is")::integer as "is",
        sum("ps")::integer as "ps"
    FROM MULTIPLY
    GROUP BY district, subdistrict, school_year
    ORDER BY district, subdistrict, school_year

);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;