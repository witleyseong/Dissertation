const pool = require("../db")

const {
  WALKING_RELEVANT_CATEGORIES,
  CRIME_DATA_EARLIEST_MONTH,
  CRIME_DATA_LATEST_MONTH,
  MIN_DENOMINATOR_KM,
} = require("../config/exposureConfig")

// Returns crimes found within a walking leg's buffer and the leg's length.
// Exported so journeyService.js can remove duplicate crimes from overlapping leg buffers.
async function getLegCrimeMatches(legCoordinates, bufferMeters){
  const query =`WITH walking_leg AS(
                  SELECT ST_SetSRID(ST_GeomFromGeoJSON($1), 4326) AS geom)
                  SELECT
                    c.id AS crime_id,
                    c.category,
                    (SELECT ST_Length(geom::geography) FROM walking_leg) AS leg_length_m
                  FROM walking_leg w
                  LEFT JOIN crimes c
                    ON ST_DWithin(w.geom::geography, c.geom::geography, $2)
                    AND c.month BETWEEN $3 AND $4
                    AND c.category = ANY($5)`

  const geojson = JSON.stringify({ type: "LineString", coordinates: legCoordinates})

  const { rows } = await pool.query(query,[
    geojson,
    bufferMeters,
    CRIME_DATA_EARLIEST_MONTH,
    CRIME_DATA_LATEST_MONTH,
    WALKING_RELEVANT_CATEGORIES,
  ])

  const legLengthMeters = Number(rows[0]?.leg_length_m ?? 0)

  // Uses a Set to prevent duplicate crime IDs and keep the count reliable
  const seen = new Set();
  const matches = [];
  for (const row of rows) {
    if (row.crime_id === null || seen.has(row.crime_id)) continue;
    seen.add(row.crime_id)
    matches.push({ crimeId: row.crime_id, category: row.category });
  }

  return {legLengthMeters, matches}
}

// Calculates crimes per km while using a minimum distance to prevent
// very short walking legs from producing unrealistically high density values.
function exposurePerKm(crimeCount, legLengthMeters) {
  const km = Math.max(legLengthMeters / 1000, MIN_DENOMINATOR_KM);
  return crimeCount / km
}


async function calculateExposure(legCoordinates, bufferMeters) {
  const { legLengthMeters, matches } = await getLegCrimeMatches(legCoordinates, bufferMeters)
  const crimeCount = matches.length;
  return {
    crimeCount,
    walkingKm: legLengthMeters / 1000,
    exposurePerKm: exposurePerKm(crimeCount, legLengthMeters),
  };
}

module.exports = { getLegCrimeMatches ,calculateExposure, exposurePerKm };
    
