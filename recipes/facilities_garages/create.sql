CREATE TEMP TABLE facilities_garages as (
    SELECT
        * 
    FROM facilities.latest
    WHERE facdomain ~* 'Core Infrastructure and Transportation'
    OR (facdomain ~* 'Administration of Government'
    AND facsubgrp ~* 'Maintenance and Garages')
);

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT *
INTO :NAME.:"VERSION"
FROM facilities_garages;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);