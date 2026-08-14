const { calculateExposure } = require("../services/exposureService");

const MIN_BUFFER_METERS = 10;
const MAX_BUFFER_METERS = 500;
const DEFAULT_BUFFER_METERS = 50;
const MAX_COORDINATES = 10000; // guards against malicious payload

// POST /api/routes/exposure
// Handles walking-leg exposure requests by validating coordinates,
// querying PostGIS through exposureService, and returning clean JSON.
async function getExposure(req, res) {
    const { coordinates, bufferMeters } = req.body;

    // Requires at least two coordinate points to form a valid line.
    if (!Array.isArray(coordinates) || coordinates.length < 2) {
        return res.status(400).json({
            error: "coordinates must be a non-empty array of at least 2 [lng, lat] points",
        });
    }
    if (coordinates.length > MAX_COORDINATES) {
        return res.status(400).json({
            error: `coordinates must not exceed ${MAX_COORDINATES} points`,
        });
    }

    // Validates that each point is a finite [lng, lat] pair within valid coordinate ranges.
    const hasInvalidPoint = coordinates.some(
    (point) =>
        !Array.isArray(point) ||
        point.length !== 2 ||
        !Number.isFinite(point[0]) ||
        !Number.isFinite(point[1]) ||
        point[0] < -180 ||
        point[0] > 180 ||
        point[1] < -90 ||
        point[1] > 90
  );
    if (hasInvalidPoint) {
        return res.status(400).json({
            error: "each coordinate must be a [lng, lat] pair with longitude in [-180, 180] and latitude in [-90, 90]",
        });
    }

    // Validates the optional buffer value to ensure it is finite and within an acceptable range.
    let buffer = DEFAULT_BUFFER_METERS;
    if (bufferMeters !== undefined) {
        if (
            typeof bufferMeters !== "number" ||
            !Number.isFinite(bufferMeters) ||
            bufferMeters < MIN_BUFFER_METERS ||
            bufferMeters > MAX_BUFFER_METERS
        ) {
            return res.status(400).json({
                error: `bufferMeters must be a finite number between ${MIN_BUFFER_METERS} and ${MAX_BUFFER_METERS}`,
            });
        }
        buffer = bufferMeters;
    }

    try {
        const result = await calculateExposure(coordinates, buffer);

        // Uses the authenticated user from req.user and preserves the existing
        // snake_case API fields for backwards compatibility.
        res.json({
            user_id: req.user.id,
            crime_count: result.crimeCount,
            walking_km: result.walkingKm,
            exposure_per_km: result.exposurePerKm,
        });
    } catch (err) {
        // Logs internal error details server-side without exposing them to the client.
        console.error(err);
        res.status(500).json({ error: "failed to calculate exposure" });
    }
}

module.exports = { getExposure };
