DROP TABLE IF EXISTS doe_pepmeetingurls;
CREATE TABLE doe_pepmeetingurls (
    url character varying,
    school_year character varying,
    readable_url character varying,
    date character varying
);

\COPY doe_pepmeetingurls FROM PSTDIN DELIMITER ',' CSV HEADER;