#!/bin/bash
source $(pwd)/bin/config.sh
BASEDIR=$(dirname $0)
NAME=$(basename $BASEDIR)
VERSION=$DATE

(
    cd $BASEDIR
    mkdir -p output
    
    docker run --rm\
        -e EDM_DATA=$EDM_DATA\
        -v $(pwd)/../:/recipes\
        -e NAME=$NAME\
        -w /recipes/$NAME\
        nycplanning/docker-geosupport:latest python3 build.py
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
    rm -rf output
)