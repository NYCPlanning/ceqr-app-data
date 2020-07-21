CREATE TEMP TABLE tmp (
    district character varying,
    subdistrict character varying,
    level character varying,
    multiplier decimal,
    grade character varying,
    school_year character varying,
    e integer
);

\COPY tmp FROM PSTDIN DELIMITER '|' CSV HEADER;
\COPY tmp TO 'output/read_to_create.csv' DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
WITH e_ps AS (
    SELECT 
        LEFT(school_year, 4) as school_year,
        district,
        subdistrict,
        CEILING(SUM(e) * multiplier) as ps
    FROM tmp
    WHERE level = 'PS'
    GROUP BY school_year, district, subdistrict, multiplier),
e_is AS (
    SELECT 
        LEFT(school_year, 4) as school_year,
        district,
        subdistrict,
        CEILING(SUM(e) * multiplier) as "is"
    FROM tmp
    WHERE level = 'IS'
    GROUP BY school_year, district, subdistrict, multiplier)
SELECT a.*,
        b.is
INTO :NAME.:"VERSION"
FROM e_ps a
JOIN e_is b 
ON a.school_year = b.school_year
AND a.district = b.district
AND a.subdistrict = b.subdistrict
ORDER BY district, subdistrict, school_year;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :"VERSION" as v, * 
    FROM :NAME.:"VERSION"
);