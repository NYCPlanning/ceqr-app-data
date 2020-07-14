CREATE TEMP TABLE tmp (
    rc_station character varying,
    count_stats_id character varying,
    rg character varying,
    region_code character varying,
    county_code character varying,
    cou character varying,
    stat character varying,
    rcsta character varying,
    ccst character varying,
    fc character varying,
    fg character varying,
    federal_direction character varying,
    f character varying,
    o character varying,
    calculation_year character varying,
    a character varying,
    aadt character varying,
    dhv character varying,
    ddhv character varying,
    su_aadt character varying,
    cu_aadt character varying,
    year_last_act character varying,
    aadt_last_act character varying,
    k_factor character varying,
    d_factor character varying,
    year_2last_act character varying,
    aadt_2last_act character varying,
    year_3last_act character varying,
    aadt_3last_act character varying,
    year_4last_act character varying,
    aadt_4last_act character varying,
    class_count_yr character varying,
    avg_wkday_f3_13 character varying,
    act_avg_truck_perc character varying,
    act_avg_su_perc character varying,
    act_avg_cu_perc character varying,
    act_avg_mc_perc character varying,
    act_avg_car_perc character varying,
    act_avg_lt_perc character varying,
    act_avg_bus_perc character varying,
    avg_wkday_f5_7 character varying,
    axle_factor character varying,
    su_peak character varying,
    cu_peak character varying,
    class_est_yr character varying,
    est_rg_fc_su character varying,
    est_rg_fc_cu character varying,
    est_rg_fc_truck character varying,
    est_rg_fc_su_peak character varying,
    est_rg_fc_cu_peak character varying,
    est_rg_fc_axle_factr character varying,
    est_fc_su character varying,
    est_fc_cu character varying,
    est_fc_truck character varying,
    est_fc_su_peak character varying,
    est_fc_cu_peak character varying,
    est_fc_axle_factr character varying,
    speed_count_yr character varying,
    speed_limit character varying,
    avg_speed character varying,
    perc_speed_50 character varying,
    perc_speed_85 character varying,
    exceeding_55 character varying,
    exceeding_65 character varying,
    avg_k_factor character varying,
    avg_d_factor character varying,
    dd_id character varying,
    borocode integer,
    geom geometry(MultiLineString,4326)
);


\COPY tmp FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS :NAME.:"VERSION" CASCADE;
SELECT *
INTO :NAME.:"VERSION"
FROM tmp;

DROP VIEW IF EXISTS :NAME.latest;
CREATE VIEW :NAME.latest AS (
    SELECT :'VERSION' as v, * 
    FROM :NAME.:"VERSION"
);