#!/bin/bash
# ============================================================
# SafeWay London — crime import (v2, wider study area)
# Loads all data.police.uk street-level CSVs into the crimes
# table, filtered to a bounding box that fully contains TfL
# Zones 1-2 (with margin), and builds the geom column.
# Safe to re-run: it clears the crimes table first.
# Run inside the container: docker exec safeway-db bash /import.sh
# ============================================================

DB="psql -U safeway -d safeway"

echo "== 0/4  Clearing existing crimes =="
$DB -c "TRUNCATE crimes;"

echo "== 1/4  Creating staging table =="
$DB -c "DROP TABLE IF EXISTS crimes_raw;
CREATE TABLE crimes_raw (
  crime_id text, month text, reported_by text, falls_within text,
  longitude text, latitude text, location text, lsoa_code text,
  lsoa_name text, crime_type text, last_outcome text, context text
);"

echo "== 2/4  Loading CSV files =="
for f in /crime-data/*/*-street.csv; do
  echo "   -> $(basename "$f")"
  $DB -c "\copy crimes_raw FROM '$f' WITH (FORMAT csv, HEADER true)"
done

echo "== 3/4  Filtering to Central London (Zones 1-2 + margin) + building geometry =="
$DB -c "
INSERT INTO crimes (external_crime_id, category, month, latitude, longitude, location_approx, geom)
SELECT
    NULLIF(crime_id, ''),
    crime_type,
    month,
    lat,
    lng,
    location,
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
ON CONFLICT (external_crime_id) DO NOTHING;"

echo "== 4/4  Cleaning up staging table =="
$DB -c "DROP TABLE crimes_raw;"

echo ""
echo "== DONE. Totals: =="
$DB -c "SELECT COUNT(*) AS total_crimes FROM crimes;"
echo "== Crimes per month: =="
$DB -c "SELECT month, COUNT(*) AS n FROM crimes GROUP BY month ORDER BY month;"
