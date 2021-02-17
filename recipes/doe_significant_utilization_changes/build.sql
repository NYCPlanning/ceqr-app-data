/*
DESCRIPTION:
    
INPUT:
    doe_all_proposals.{version} (
        dbn character varying,
        main_building_id character varying,
        proposal_title character varying,
        other_impacted_building character varying,
        pep_vote character varying,
        approved character varying,
        at_scale_year character varying
    )
    
    doe_pepmeetingurls (
        url character varying,
        school_year character varying,
        readable_url character varying,
        date character varying,
        join_key character varying
    )

OUTPUT: 
    TEMP tmp 
*/
CREATE TEMP TABLE tmp as (
    WITH _tmp AS (
        SELECT
            *,
            (CASE 
                WHEN EXTRACT(month from pep_vote::timestamp) < 9
                    THEN (EXTRACT(year from pep_vote::timestamp) - 1)::text||
                        '-'||EXTRACT(year from pep_vote::timestamp)::text
                WHEN EXTRACT(month from pep_vote::timestamp) >= 9
                    THEN EXTRACT(year from pep_vote::timestamp)::text||
                    '-'||(EXTRACT(year from pep_vote::timestamp) + 1)::text
                ELSE NULL
            END) as school_year
        FROM doe_all_proposals."2021/02/17"
    )
    SELECT
        a.main_building_id as bldg_id,
        RIGHT(a.dbn, 4) as org_id,
        a.other_impacted_building as bldg_id_additional,
        a.proposal_title as title,
        a.at_scale_year as at_scale_year,
        NULL as url,
        a.school_year,
        NULLIF(
            regexp_replace(SPLIT_PART(a.at_scale_school_enrollment, '-', 1), '[^0-9]|\s', '', 'g'), 
            '')::integer as at_scale_enroll,
        a.pep_vote as vote_date
    FROM _tmp a
    JOIN doe_pepmeetingurls b
    ON a.school_year = b.school_year
    AND a.pep_vote = b.date
    WHERE a.approved = 'Approved';
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;