CREATE TEMP TABLE tmp (
    district character varying,
    subdistrict character varying,
    level character varying,
    multiplier numeric,
    school_year character varying,
    e integer
);

\COPY tmp FROM PSTDIN DELIMITER '|' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
WITH e_ps AS (
    SELECT 
        LEFT(year, 4) as school_year,
        district,
        subdistrict,
        SUM(e) * multiplier as ps
    FROM tmp
    GROUP BY year, district, subdistrict, multiplier
    WHERE level = 'ps'),
e_is AS (
    SELECT 
        LEFT(year, 4) as school_year,
        district,
        subdistrict,
        SUM(e) * multiplier as "is"
    FROM tmp
    GROUP BY year, district, subdistrict, multiplier
    WHERE level = 'is')
SELECT a.*,
        b.is
INTO :NAME.:"VERSION"
FROM e_ps a
JOIN e_is b 
ON a.school_year = b.school_year
AND a.district = b.district
AND a.subdistrict = b.subdistrict;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :"VERSION" as v, * 
    FROM :NAME.:"VERSION"
);