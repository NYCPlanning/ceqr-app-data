#!/bin/bash
source $(pwd)/bin/config.sh
BASEDIR=$(dirname $0)
VERSION=$DATE

(
    cd $BASEDIR
    echo "loading into table atypical_roadways.\"$VERSION\""
    psql $RECIPE_ENGINE -c "\COPY (
        SELECT 
            street AS streetname, 
            segmentid, 
            streetwidth_min,
            streetwidth_max, 
            lzip AS left_zipcode, 
            rzip AS right_zipcode,
            LEFT(StreetCode, 1) AS borocode, 
            nodelevelf, 
            nodelevelt,
            featuretyp, 
            trafdir, 
            nullif(number_total_lanes, '  ')::NUMERIC AS number_total_lanes, 
            trim(bikelane) AS bikelane, 
            wkb_geometry AS geom
        FROM dcp_lion.latest
        WHERE ((nodelevelf!= 'M' AND nodelevelf!= '*' AND nodelevelf!= '$')
        OR (nodelevelt!= 'M' AND nodelevelt!= '*' AND nodelevelt!= '$'))
        AND trafdir != 'P'
        AND featuretyp != '1'
        AND (nullif(number_total_lanes, '  ')::NUMERIC != 1
        OR nullif(number_total_lanes, '  ')::NUMERIC IS NULL)
        AND trim(bikelane) != '1'
        AND trim(bikelane) != '2'
        AND trim(bikelane) != '4'
        AND trim(bikelane) != '9'
    ) TO stdout DELIMITER ',' CSV HEADER" | 
    psql $EDM_DATA -v VERSION=$VERSION -f create.sql

    mkdir -p output && 
    (
        cd output

        # Export to CSV
        psql $EDM_DATA -c "\COPY (
            SELECT * FROM atypical_roadways.\"$VERSION\"
        ) TO stdout DELIMITER ',' CSV HEADER;" > atypical_roadways.csv

        # Export to ShapeFile
        SHP_export $EDM_DATA atypical_roadways.$VERSION LINESTRING atypical_roadways

        # Write VERSION info
        echo "$VERSION" > version.txt
        
    )
)