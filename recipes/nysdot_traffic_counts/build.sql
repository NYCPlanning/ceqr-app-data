CREATE TEMP TABLE tmp as (
    SELECT 
        a.rc_station,
        a.count_stats_id,
        a.rg,
        a.region_code,
        a.borocode,
        a.county_code,
        a.cou,
        a.stat,
        a.rcsta,
        a.ccst,
        a.fc,
        a.fg,
        a.federal_direction,
        a.f,
        a.o,
        a.calculation_year,
        a.a,
        a.aadt,
        a.dhv,
        a.ddhv,
        a.su_aadt,
        a.cu_aadt,
        a.year_last_act,
        a.aadt_last_act,
        a.k_factor,
        a.d_factor,
        a.year_2last_act,
        a.aadt_2last_act,
        a.year_3last_act,
        a.aadt_3last_act,
        a.year_4last_act,
        a.aadt_4last_act,
        a.class_count_yr,
        a.avg_wkday_f3_13,
        a.act_avg_truck_perc,
        a.act_avg_su_perc,
        a.act_avg_cu_perc,
        a.act_avg_mc_perc,
        a.act_avg_car_perc,
        a.act_avg_lt_perc,
        a.act_avg_bus_perc,
        a.avg_wkday_f5_7,
        a.axle_factor,
        a.su_peak,
        a.cu_peak,
        a.class_est_yr,
        a.est_rg_fc_su,
        a.est_rg_fc_cu,
        a.est_rg_fc_truck,
        a.est_rg_fc_su_peak,
        a.est_rg_fc_cu_peak,
        a.est_rg_fc_axle_factr,
        a.est_fc_su,
        a.est_fc_cu,
        a.est_fc_truck,
        a.est_fc_su_peak,
        a.est_fc_cu_peak,
        a.est_fc_axle_factr,
        a.speed_count_yr,
        a.speed_limit,
        a.avg_speed,
        a.perc_speed_50,
        a.perc_speed_85,
        a.exceeding_55,
        a.exceeding_65,
        a.avg_k_factor,
        a.avg_d_factor,
        a.dd_id,
        b.geom
    FROM (
        SELECT 
            *,
            (CASE
                WHEN cou = '061' THEN 1
                WHEN cou = '005' THEN 2
                WHEN cou = '047' THEN 3
                WHEN cou = '081' THEN 4
                WHEN cou = '085' THEN 5
            END) as borocode
        FROM nysdot_traffic.latest
        WHERE cou in ('005', '047','061','081','085')
    ) a
    LEFT JOIN (
        SELECT 
            rc_id AS rc_station, 
            wkb_geometry AS geom
        FROM nysdot_aadt.latest
    ) b
    ON a.rc_station = b.rc_station
);

\COPY tmp TO PSTDOUT DELIMITER ',' CSV HEADER;
