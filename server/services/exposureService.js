const pool = require("../db")

async function calculateExposure(legCoordinates, bufferMeters = 50) {
    const query =`
    WITH walking_leg AS (
        SELECT ST_SetSRID(
            ST_GeomFromGeoJSON($1),
            4326
        ) AS geom
    ),
     matched AS (
      SELECT
        w.geom AS leg_geom,
        COUNT(c.id) AS crime_count
      FROM walking_leg w
      LEFT JOIN crimes c
        ON ST_DWithin(w.geom::geography, c.geom::geography, $2)
      GROUP BY w.geom
    )
    SELECT
      crime_count,
      ST_Length(leg_geom::geography) / 1000.0 AS walking_km,
      crime_count / GREATEST(ST_Length(leg_geom::geography) / 1000.0, 0.001) AS exposure_per_km
    FROM matched;
  `;

  const geojson = JSON.stringify({
    type: "LineString",
    coordinates: legCoordinates,
  });

  const result = await pool.query(query, [geojson, bufferMeters]);
  return result.rows[0];
}

// same bufer as calculateExp, grouped by crime categ
// different of single total

async function getCrimeBreakdown(legCoodinates, bufferMeters = 50) {
  const query = `
  WITH walking_leg AS (
    SELECT ST_SetSRID(
      ST_GeomFromGeoJSON($1),
      4326
    ) AS geom
    )
    SELECT c.category, COUNT(*)::int AS count
    FROM walking_leg w
    JOIN crimes c
      ON ST_DWithin(w.geom::geographym c.geom::geography, $2)
      GROUP BY c.category
      ORDER BY count DESC;
    `;

    const geojson = JSON.stringify({
      type: "LineString",
      coordinates: legCoodinates,
    });
    const result = await pool.query(query, [geojson, bufferMeters]);

    const breakdown = {};
    for (const row of result.rows) {
      breakdown[row.category] = row.count;
    }
    return breakdown;

}

module.exports = { calculateExposure, getCrimeBreakdown };
    
