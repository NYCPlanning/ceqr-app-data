CREATE TEMP TABLE tmp as (
    WITH 
    UNPIVOT as (
        SELECT 
            t.district,
            t.projected, 
            col_name as year, 
            (CASE WHEN t.projected in 
                ('PK','K','1','2','3','4','5','6') 
                THEN replace(col_value, ',', '')::integer 
            END) as "ps", 
            (CASE WHEN t.projected in ('7','8') 
                THEN replace(col_value, ',', '')::integer 
            END) as "is"
        from sca_e_projections."2019" t
        JOIN LATERAL (VALUES
            ('2018_19', t."2018_19"),
            ('2019_20', t."2019_20"),
            ('2020_21', t."2020_21"),
            ('2021_22', t."2021_22"),
            ('2022_23', t."2022_23"),
            ('2024_25', t."2024_25"),
            ('2025_26', t."2025_26"),
            ('2026_27', t."2026_27"),
            ('2027_28', t."2027_28"),
            ('2028_29', t."2028_29")
        ) s(col_name, col_value) ON TRUE
    ),
    MULTIPLY as (
        SELECT
            a.district, 
            LEFT(a.year,4) as year,
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
        year as school_year,
        district,
        subdistrict,
        sum("is")::integer as "is",
        sum("ps")::integer as "ps"
    FROM MULTIPLY
    GROUP BY district, subdistrict, year
    ORDER BY district, subdistrict, year
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;