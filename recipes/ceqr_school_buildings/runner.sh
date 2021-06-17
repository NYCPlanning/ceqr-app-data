#!/bin/bash
source $(pwd)/bin/config.sh
BASEDIR=$(dirname $0)
NAME=$(basename $BASEDIR)
VERSION=$DATE

(
    cd $BASEDIR
    mkdir -p output
    endpoint=https://edm-recipes.nyc3.digitaloceanspaces.com
    V=$(curl $endpoint/datasets/doe_lcgms/latest/config.json | jq -r '.dataset.version')
    curl $endpoint/datasets/doe_lcgms/$V/doe_lcgms.sql | psql $RECIPE_ENGINE

    psql -q $RECIPE_ENGINE -f build.sql| 
    psql $EDM_DATA -v NAME=$NAME -v VERSION=$VERSION -f create.sql

    (
        cd output
        
        # Export to CSV
        psql $EDM_DATA -c "\COPY (
            SELECT * FROM $NAME.\"$VERSION\"
        ) TO stdout DELIMITER ',' CSV HEADER;" > $NAME.csv

        # Export to ShapeFile
        SHP_export $EDM_DATA $NAME.$VERSION POINT $NAME

        # Write VERSION info
        echo "$VERSION" > version.txt
        
    )

    Upload $NAME $VERSION
    Upload $NAME latest
)