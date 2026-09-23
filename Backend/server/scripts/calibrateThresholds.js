// picks random short walks in London and prints the crimes per km percentiles,
// used to choose the exposure thresholds. Run: node scripts/calibrateThresholds.js
const pool = require("../db");
const {
  WALK_BUFFER_METERS,
  WALKING_RELEVANT_CATEGORIES,
  CRIME_DATA_EARLIEST_MONTH,
  CRIME_DATA_LATEST_MONTH,
} = require("../config/exposureConfig");

const SAMPLE_COUNT = 800;
// same area that load-crimes.sh keeps (central London)
const BBOX = { lngMin: -0.25, lngMax: 0.02, latMin: 51.42, latMax: 51.59 };

function percentile(sorted, p) {
  const idx = (sorted.length - 1) * p;
  const lo = Math.floor(idx);
  const hi = Math.ceil(idx);
  if (lo === hi) return sorted[lo];
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo);
}

async function run() {
  const query = `
    WITH sample_line AS (
      SELECT ST_SetSRID(ST_MakeLine(
        ST_MakePoint($1::float8, $2::float8),
        ST_MakePoint($1::float8 + $3::float8, $2::float8 + $4::float8)
      ), 4326) AS geom
    )
    SELECT
      ST_Length(geom::geography) AS length_m,
      (SELECT COUNT(*) FROM crimes c
        WHERE ST_DWithin(sample_line.geom::geography, c.geom::geography, $5)
          AND c.month BETWEEN $6 AND $7
          AND c.category = ANY($8)
      ) AS crime_count
    FROM sample_line;
  `;

  const perKm = [];
  const totals = [];

  for (let i = 0; i < SAMPLE_COUNT; i++) {
    const lng1 = BBOX.lngMin + Math.random() * (BBOX.lngMax - BBOX.lngMin);
    const lat1 = BBOX.latMin + Math.random() * (BBOX.latMax - BBOX.latMin);
    const dlng = (Math.random() - 0.5) * 0.006;
    const dlat = (Math.random() - 0.5) * 0.006;

    const { rows } = await pool.query(query, [
      lng1, lat1, dlng, dlat,
      WALK_BUFFER_METERS,
      CRIME_DATA_EARLIEST_MONTH, CRIME_DATA_LATEST_MONTH,
      WALKING_RELEVANT_CATEGORIES,
    ]);

    const lengthKm = Number(rows[0].length_m) / 1000;
    const count = Number(rows[0].crime_count);
    totals.push(count);
    perKm.push(lengthKm > 0 ? count / lengthKm : 0);
  }

  perKm.sort((a, b) => a - b);
  totals.sort((a, b) => a - b);

  console.log(`n = ${SAMPLE_COUNT}`);
  console.log("crimes per km  -> p50=%s p75=%s p90=%s p95=%s max=%s",
    percentile(perKm, 0.5).toFixed(0), percentile(perKm, 0.75).toFixed(0),
    percentile(perKm, 0.9).toFixed(0), percentile(perKm, 0.95).toFixed(0),
    perKm[perKm.length - 1].toFixed(0));
  console.log("raw crimeCount -> p50=%s p75=%s p90=%s p95=%s max=%s",
    percentile(totals, 0.5).toFixed(0), percentile(totals, 0.75).toFixed(0),
    percentile(totals, 0.9).toFixed(0), percentile(totals, 0.95).toFixed(0),
    totals[totals.length - 1].toFixed(0));

  await pool.end();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
