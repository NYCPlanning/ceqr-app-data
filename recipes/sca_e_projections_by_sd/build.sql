/*
DESCRIPTION:
    1. Unpivot sca_e_projections so that we get a table like the following: 

        district |  projected  | school_year |  ps  |  is  
       ----------+-------------+-------------+------+------
        1        | PK          | 2018        |  XXX |  NULL  
        4        | PK          | 2022        |  XXX |  NULL
        ...      | ...         | ...         |  ... |   ...
        5        | 7           | 2023        |  NULL|   XXX
        1        | 8           | 2026        |  NULL|   XXX
        ...      | ...         | ...         |  ... |   ...

    2. FULL OUTER JOIN sca_e_projections and sca_e_pct, so that
    we can calculate subdistrict level "is" and "ps" for each 
    school year by applyiny the multipliers. 
        "is" is defined as grade ('7','8') 
        "ps" is defined as grade ('PK','K','1','2','3','4','5','6')
    
    3. Aggregate over district, subdistrict, school_year by taking
    the ceiling of the sum for "is" and "ps"

INPUT:
    sca_e_projections.:"VERSION" (
        district character varying,
        projected character varying,
        "2018_19" character varying,
        "2019_20" character varying,
        "2020_21" character varying,
        "2021_22" character varying,
        "2022_23" character varying,
        "2023_24" character varying,
        "2024_25" character varying,
        "2025_26" character varying,
        "2026_27" character varying,
        "2027_28" character varying,
        "2028_29" character varying
    )

    sca_e_pct.:"VERSION" (
        id character varying,
        district character varying,
        subdistrict character varying,
        level character varying,
        multiplier character varying
    )

OUTPUT:

    TEMP tmp (
        school_year text,
        district character varying,
        subdistrict character varying,
        ps numeric,
        is numeric
    )

*/
CREATE TEMP TABLE tmp as (
    WITH 
    UNPIVOT as (
		SELECT
		    a._col ->> 'borough' as district, 
		    UPPER(REPLACE(b.key, 'grade_', '')) as projected,
		    LEFT(a._col ->> 'year', 4) as school_year,
		    (CASE WHEN b.key in ('pk','k','grade_1','grade_2','grade_3','grade_4','grade_5','grade_6') 
		           THEN replace(b.value, ',', '')::integer 
		     END) as "ps",
		    (CASE WHEN b.key in ('grade_7','grade_8') 
		        THEN replace(b.value, ',', '')::integer 
		    END) as "is"
		    
		FROM (
			SELECT row_to_json(row) as _col 
			FROM (SELECT * FROM sca_e_projections."2020") row) a,
			json_each_text(_col) as b
		WHERE b.key not in ('ogc_fid', 'borough', 'data_type', 'year')),
	MULTIPLY as (
        SELECT
            a.district, 
            a.school_year,
            a.projected,
            a."is"* b.multiplier::numeric as "is",
            a."ps"* b.multiplier::numeric as "ps",
            b.subdistrict
        FROM UNPIVOT a
        FULL OUTER JOIN sca_e_pct."2020" b
        ON a.district = b.district
        WHERE a.projected IN 
            ('PK','K','1','2','3',
            '4','5','6','7','8')
        AND NOT a.district ~* 'HS'
    )
    SELECT
        school_year,
        district,
        subdistrict,
        CEILING(sum("is"))::integer as "is",
        CEILING(sum("ps"))::integer as "ps"
    FROM MULTIPLY
    GROUP BY district, subdistrict, school_year
    ORDER BY district, subdistrict, school_year

);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;