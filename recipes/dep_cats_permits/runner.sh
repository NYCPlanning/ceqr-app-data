#!/bin/bash
source $(pwd)/bin/config.sh
BASEDIR=$(dirname $0)
NAME=$(basename $BASEDIR)
VERSION=$DATE

(
    cd $BASEDIR
    docker run --rm\
        -v $(pwd)/../:/recipes\
        -w /recipes/$NAME\
        nycplanning/docker-geosupport:latest python3 build.py | 
    psql $EDM_DATA -v VERSION=$VERSION -f create.sql

    mkdir -p output && 
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
)