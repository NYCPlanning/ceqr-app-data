CREATE TEMP TABLE tmp as (
    WITH combined AS
        (SELECT
            district,
            school as name,
            borough,
            address,
            COALESCE(number_of_seats, '0') as capacity,
            REPLACE("opening_&_anticipated_opening",'SEPTEMBER ', '') as start_date,
            '15-19' as capital_plan
        FROM sca_capacity_projects_prev.latest
        UNION
        SELECT
            district,
            school as name,
            borough,
            location as address,
            COALESCE(capacity, '0') as capacity,
            anticipated_opening as start_date,
            '20-24' as capital_plan
        FROM sca_capacity_projects_current.latest
        UNION
        SELECT
            district,
            school as name,
            borough,
            location as address,
            COALESCE(capacity, '0') as capacity,
            anticipated_opening as start_date,
            '20-24' as capital_plan
        FROM sca_capacity_projects_tcu.latest),

    org_levels AS
        (SELECT 
            md5(CAST((c.*) AS text)) as uid,
            c.name,
            CASE
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%3K%' THEN '3K'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%PK%' THEN 'PK'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%PREK%' THEN 'PK'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%PSIS%' THEN 'PSIS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%ISHS%' THEN 'ISHS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%PSHS%' THEN 'PSHS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%PS%' THEN 'PS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%IS%' THEN 'IS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%MS%' THEN 'IS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%HS%' THEN 'HS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%HIGH%' THEN 'HS'
                WHEN REGEXP_REPLACE(c.name, '[^\w]+','','g') LIKE '%D75%' THEN NULL
            END as org_level
            c.district,
            c.capacity,
            CASE
                WHEN borough = 'M' THEN 'Manhattan'
                WHEN borough = 'X' THEN 'Bronx'
                WHEN borough = 'K' THEN 'Brooklyn'
                WHEN borough = 'Q' THEN 'Queens'
                WHEN borough = 'R' THEN 'Staten Island'
            END as borough,
            c.address,
            c.start_date,
            c.capital_plan,
        
        FROM combined c)

    SELECT
        a.uid,
        a.org_level,
        a.district,
        a.capacity,
        CASE 
            WHEN org_level = 'PS' THEN 1
            WHEN org_level = 'PSIS' THEN 0.5
            WHEN org_level = 'PSHS' THEN 0.5
            ELSE 0
        END as pct_ps,
        CASE 
            WHEN org_level = 'IS' THEN 1
            WHEN org_level = 'PSIS' THEN 0.5
            WHEN org_level = 'ISHS' THEN 0.5
            ELSE 0
        END as pct_is,
            CASE 
            WHEN org_level = 'HS' THEN 1
            WHEN org_level = 'PSHS' THEN 0.5
            WHEN org_level = 'ISHS' THEN 0.5
            ELSE 0
        END as pct_hs,
        CASE
            WHEN org_level in ('PSIS','PSHS','ISHS') THEN TRUE
            ELSE FALSE
        END as guessed_pct,
        a.start_date,
        a.capital_plan,
        a.borough,
        a.address
            
    FROM org_levels a
);

\COPY tmp TO 'output/_sca_capacity_projects.csv' DELIMITER ',' CSV HEADER;