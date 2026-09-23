#!/bin/bash
# loads the crime CSVs from /crime_db (the db/crime_db folder) into the crimes table
# runs inside the postgres container on first start, and again with ./import.sh
set -e

CSV_DIR="/crime_db"
DB="psql -v ON_ERROR_STOP=1 -U safeway -d safeway"

if ! ls "$CSV_DIR"/*/*-street.csv >/dev/null 2>&1; then
  echo "No crime CSVs found in db/crime_db/, skipping (crimes table stays empty)"
  exit 0
fi

echo "== Loading crime data (takes a few minutes) =="
$DB <<'SQL'
TRUNCATE crimes;
DROP TABLE IF EXISTS crimes_raw;
CREATE TABLE crimes_raw (
  crime_id text, month text, reported_by text, falls_within text,
  longitude text, latitude text, location text, lsoa_code text,
  lsoa_name text, crime_type text, last_outcome text, context text
);
SQL

for f in "$CSV_DIR"/*/*-street.csv; do
  echo "   -> $(basename "$f")"
  $DB -c "\copy crimes_raw FROM '$f' WITH (FORMAT csv, HEADER true)"
done

echo "== Filtering to Central London + building geometry =="
$DB <<'SQL'
INSERT INTO crimes (external_crime_id, category, month, latitude, longitude, location_approx, geom)
SELECT NULLIF(crime_id, ''), crime_type, month, lat, lng, location,
       ST_SetSRID(ST_MakePoint(lng, lat), 4326)
FROM (
    SELECT crime_id, crime_type, month, location,
           longitude::float8 AS lng,
           latitude::float8  AS lat
    FROM crimes_raw
    WHERE longitude ~ '^-?[0-9.]+$'
      AND latitude  ~ '^-?[0-9.]+$'
) t
WHERE lng BETWEEN -0.25 AND 0.02
  AND lat BETWEEN 51.42 AND 51.59
ON CONFLICT (external_crime_id) DO NOTHING;
DROP TABLE crimes_raw;
SQL

$DB -c "SELECT COUNT(*) AS total_crimes FROM crimes;"
