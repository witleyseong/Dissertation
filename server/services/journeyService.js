const pool = require("../db");
const { getLegCrimeMatches, exposurePerKm } = require("./exposureService");
const {
    WALK_BUFFER_METERS,
    MIN_DENOMINATOR_KM,
    EXPOSURE_LOWER_MAX_PER_KM,
    EXPOSURE_MODERATE_MAX_PER_KM,
    EXPOSURE_SCORE_HALF_LIFE_PER_KM,
    RISK_TO_EXPOSURE_LEVEL,
} = require("../config/exposureConfig");

const TFL_BASE_URL = "https://api.tfl.gov.uk/Journey/JourneyResults";
const TFL_MODES = "tube,bus,walking,elizabeth-line,dlr,overground";
const TFL_REQUEST_TIMEOUT_MS = 8000;

// Defines error types so controllers can return the correct HTTP status
// without exposing TfL response data or API keys.
class TflConfigError extends Error { }   // missing or invalid setup = 500
class TflTimeoutError extends Error { }  // upstream took too long = 503
class TflUpstreamError extends Error {  // upstream responded with an error = 502
    constructor(message, status) {
        super(message);
        this.upstreamStatus = status;
    }
}

function redactApiKey(text) {
    return typeof text === "string" ? text.replace(/app_key=[^&\s]+/gi, "app_key=REDACTED") : text;
}

// Legacy risk-level classification kept for Swift app compatibility.
// It classifies historical recorded-crime exposure near the leg, not the probability of harm.
function riskLevelFor(crimeCount, perKm) {
    if (crimeCount === 0) return "safe";
    if (perKm <= EXPOSURE_LOWER_MAX_PER_KM) return "low";
    if (perKm <= EXPOSURE_MODERATE_MAX_PER_KM) return "moderate";
    return "high";
}

function exposureLevelFor(riskLevel) {
    return riskLevel === null ? null : RISK_TO_EXPOSURE_LEVEL[riskLevel];
}

// Calculates a 0–100 score from crime density (crimes/km), keeping it
// consistent with the exposure level classification. Higher density produces a lower score.
function exposureScoreFor(perKm) {
    return Math.round(100 / (1 + perKm / EXPOSURE_SCORE_HALF_LIFE_PER_KM));
}

function formatTime(isoString) {
    if (!isoString) return null;
    const d = new Date(isoString);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function midpointOf(coords) {
    if (!coords || coords.length === 0) return null;
    return coords[Math.floor(coords.length / 2)];
}


// Converts TfL [lat, lng] coordinates to the standard [lng, lat] format
// used by PostGIS and the API response.
function parseLineString(leg) {
    if (!leg.path || !leg.path.lineString) return [];
    try {
        const raw = JSON.parse(leg.path.lineString);
        if (!Array.isArray(raw)) return [];
        return raw
            .filter((pt) => Array.isArray(pt) && pt.length === 2 && Number.isFinite(pt[0]) && Number.isFinite(pt[1]))
            .map(([lat, lng]) => [lng, lat]);
    } catch {
        return [];
    }
}

function buildTflUrl(from, to) {
    const url = new URL(`${TFL_BASE_URL}/${encodeURIComponent(from)}/to/${encodeURIComponent(to)}`);
    url.searchParams.set("mode", TFL_MODES);
    url.searchParams.set("includeAlternativeRoutes", "true");
    url.searchParams.set("app_key", process.env.TFL_APP_KEY);
    return url.toString();
}


// Handles ambiguous TfL locations by selecting the top match for each
// location, converting it to coordinates, and retrying the request once.
function pickBestMatch(disambiguation) {
    const options = disambiguation?.disambiguationOptions || [];
    if (options.length === 0) return null;
    const best = [...options].sort((a, b) => (b.matchQuality || 0) - (a.matchQuality || 0))[0];
    return `${best.place.lat},${best.place.lon}`;
}

async function fetchWithTimeout(url) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TFL_REQUEST_TIMEOUT_MS);
    try {
        return await fetch(url, { signal: controller.signal });
    } catch (err) {
        if (err.name === "AbortError") {
            throw new TflTimeoutError("TfL Journey API did not respond in time");
        }
        throw new TflUpstreamError(redactApiKey(err.message), null);
    } finally {
        clearTimeout(timeout);
    }
}

async function fetchTflJourney(from, to) {
    if (!process.env.TFL_APP_KEY) {
        throw new TflConfigError("TFL_APP_KEY is not set — register a free key at api-portal.tfl.gov.uk and add it to .env");
    }

    let response = await fetchWithTimeout(buildTflUrl(from, to));

    if (response.status === 300) {
        let body;
        try {
            body = await response.json();
        } catch {
            throw new TflUpstreamError("TfL returned a malformed disambiguation response", 300);
        }
        const resolvedFrom = pickBestMatch(body.fromLocationDisambiguation) || from;
        const resolvedTo = pickBestMatch(body.toLocationDisambiguation) || to;
        response = await fetchWithTimeout(buildTflUrl(resolvedFrom, resolvedTo));
    }


    // Treats TfL route-not-found responses as a normal empty journey result
    // rather than an upstream API failure.
    if (response.status === 404) {
        return { journeys: [] };
    }

    if (!response.ok) {
        // Log the real upstream body server-side for debugging, but never hand
        // it to the client — it's TfL's internal error text, not ours to expose.
        const rawBody = await response.text().catch(() => "");
        console.error(`TfL API error ${response.status}:`, redactApiKey(rawBody));
        throw new TflUpstreamError(`TfL Journey API responded with ${response.status}`, response.status);
    }

    try {
        return await response.json();
    } catch {
        throw new TflUpstreamError("TfL returned a malformed JSON response", response.status);
    }
}


async function buildLeg(rawLeg) {
    const isWalking = rawLeg.mode?.id === "walking";
    const coords = parseLineString(rawLeg);

    const base = {
        isWalking,
        modeId: rawLeg.mode?.id || "unknown",
        mode: rawLeg.mode?.name || rawLeg.mode?.id || "unknown",
        routeName: rawLeg.routeOptions?.[0]?.name || null,
        duration: rawLeg.duration ?? null,
        lineString: coords,
    };

    // Skips exposure analysis for non-walking or invalid legs and returns
    // predictable null exposure fields instead of failing the whole request.
    if (!isWalking || coords.length < 2) {
        return {
            ...base,
            crimeCount: null,
            riskLevel: null,
            exposureLevel: null,
            walkingKm: null,
            exposurePerKm: null,
            midpoint: null,
            _matches: [],
        };
    }

    const { legLengthMeters, matches } = await getLegCrimeMatches(coords, WALK_BUFFER_METERS);
    const crimeCount = matches.length;
    const walkingKm = legLengthMeters / 1000;
    const perKm = exposurePerKm(crimeCount, legLengthMeters);
    const riskLevel = riskLevelFor(crimeCount, perKm);

    return {
        ...base,
        crimeCount,
        riskLevel,
        exposureLevel: exposureLevelFor(riskLevel),
        walkingKm,
        exposurePerKm: perKm,
        midpoint: crimeCount > 0 ? midpointOf(coords) : null,
        // Used internally to de-duplicate journey-level data and removed before
        // the leg is returned to the client.
        _matches: matches,
    };
}

async function buildJourney(rawJourney, index) {
    const legs = await Promise.all((rawJourney.legs || []).map(buildLeg));

    const walkingLegs = legs.filter((leg) => leg.isWalking && leg.crimeCount !== null);

    // De-duplicates crimes found across overlapping walking-leg buffers so each
    // crime is counted only once in the journey total and category breakdown.
    const uniqueCrimes = new Map();
    for (const leg of legs) {
        for (const match of leg._matches) {
            uniqueCrimes.set(match.crimeId, match.category);
        }
    }

    const totalCrimeExposure = uniqueCrimes.size;
    const crimeBreakdown = {};
    for (const category of uniqueCrimes.values()) {
        crimeBreakdown[category] = (crimeBreakdown[category] || 0) + 1;
    }

    const totalWalkingKm = walkingLegs.reduce((sum, leg) => sum + leg.walkingKm, 0);

    // Returns null scores when a journey has no measurable walking exposure,
    // avoiding a misleading default safety classification.
    const hasMeasurableWalking = totalWalkingKm > 0;
    const journeyExposurePerKm = hasMeasurableWalking
        ? exposurePerKm(totalCrimeExposure, totalWalkingKm * 1000)
        : null;
    const journeyRiskLevel = hasMeasurableWalking ? riskLevelFor(totalCrimeExposure, journeyExposurePerKm) : null;

    const transitLegCount = legs.filter((leg) => !leg.isWalking).length;

    // Uses TfL's actual journey fare in pence when available,
    // otherwise returns null so the field remains present in the API response.
    const fare = rawJourney.fare?.totalCost != null ? rawJourney.fare.totalCost / 100 : null;

    return {
        id: `journey-${index}`,
        duration: rawJourney.duration ?? null,
        departureTime: formatTime(rawJourney.startDateTime),
        arrivalTime: formatTime(rawJourney.arrivalDateTime),
        numChanges: Math.max(0, transitLegCount - 1),
        // Legacy field, kept for the existing Swift app. See exposureScoreFor().
        safetyScore: hasMeasurableWalking ? exposureScoreFor(journeyExposurePerKm) : null,
        exposureScore: hasMeasurableWalking ? exposureScoreFor(journeyExposurePerKm) : null,
        totalCrimeExposure,
        totalWalkingKm,
        exposurePerKm: journeyExposurePerKm,
        riskLevel: journeyRiskLevel,
        exposureLevel: exposureLevelFor(journeyRiskLevel),
        fare,
        crimeBreakdown,
        legs: legs.map(({ _matches, ...leg }) => leg),
    };
}


async function planJourneys(from, to) {
    const tflResponse = await fetchTflJourney(from, to);
    const rawJourneys = tflResponse.journeys || [];
    const journeys = await Promise.all(rawJourneys.map((journey, i) => buildJourney(journey, i)));

    // Marks the fastest and lowest-exposure journeys without changing TfL's
    // original ordering or IDs. Tied journeys are all marked as true.
    const withDuration = journeys.filter((j) => j.duration !== null);
    const minDuration = withDuration.length > 0 ? Math.min(...withDuration.map((j) => j.duration)) : null;

    // Compares only journeys with measured walking exposure when identifying
    // the lowest-exposure option.
    const measured = journeys.filter((j) => j.totalWalkingKm > 0);
    const minExposure = measured.length > 0 ? Math.min(...measured.map((j) => j.totalCrimeExposure)) : null;

    for (const journey of journeys) {
        journey.isFastest = minDuration !== null && journey.duration === minDuration;
        journey.isLowestExposure = minExposure !== null && journey.totalWalkingKm > 0 && journey.totalCrimeExposure === minExposure;
    }

    return journeys;
}

// Persists each returned journey as a route_option, its legs as route_legs,
// and (when walking exposure was measured) a route_scores row, all inside a
// single transaction so a partially written journey never lingers in the DB.
async function persistJourneys(journeyRequestId, journeys) {
    const fastestJourney = journeys.find((j) => j.isFastest);
    const fastestExposurePerKm = fastestJourney ? fastestJourney.exposurePerKm : null;

    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        for (const journey of journeys) {
            const tflRouteIndex = Number(journey.id.replace("journey-", ""));
            const summary = journey.legs.map((leg) => leg.mode).join(" → ");
            const walkingLegCount = journey.legs.filter((leg) => leg.isWalking).length;

            const { rows: routeRows } = await client.query(
                `INSERT INTO route_options
                    (journey_request_id, tfl_route_index, summary, total_duration_seconds,
                     total_walking_distance_m, walking_leg_count, is_fastest, is_recommended)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
                 RETURNING id`,
                [
                    journeyRequestId,
                    tflRouteIndex,
                    summary,
                    journey.duration,
                    journey.totalWalkingKm * 1000,
                    walkingLegCount,
                    journey.isFastest,
                    journey.isLowestExposure,
                ]
            );
            const routeOptionId = routeRows[0].id;

            for (let i = 0; i < journey.legs.length; i++) {
                const leg = journey.legs[i];
                const geojson = leg.lineString && leg.lineString.length >= 2
                    ? JSON.stringify({ type: "LineString", coordinates: leg.lineString })
                    : null;

                await client.query(
                    `INSERT INTO route_legs
                        (route_option_id, leg_order, mode, duration_seconds, distance_m, instruction, geom)
                     VALUES ($1,$2,$3,$4,$5,$6, ST_SetSRID(ST_GeomFromGeoJSON($7), 4326))`,
                    [
                        routeOptionId,
                        i,
                        leg.modeId,
                        leg.duration,
                        leg.walkingKm != null ? leg.walkingKm * 1000 : null,
                        leg.routeName,
                        geojson,
                    ]
                );
            }

            if (journey.totalWalkingKm > 0) {
                const exposureReductionPct = fastestExposurePerKm
                    ? ((fastestExposurePerKm - journey.exposurePerKm) / fastestExposurePerKm) * 100
                    : null;

                await client.query(
                    `INSERT INTO route_scores
                        (route_option_id, buffer_distance_m, crime_count, total_walking_distance_km,
                         exposure_per_km, exposure_reduction_pct)
                     VALUES ($1,$2,$3,$4,$5,$6)`,
                    [
                        routeOptionId,
                        WALK_BUFFER_METERS,
                        journey.totalCrimeExposure,
                        journey.totalWalkingKm,
                        journey.exposurePerKm,
                        exposureReductionPct,
                    ]
                );
            }
        }

        await client.query(`UPDATE journey_requests SET status = 'complete' WHERE id = $1`, [journeyRequestId]);
        await client.query("COMMIT");
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
}

// Wraps planJourneys with persistence: logs the request against the user
// before calling TfL, then saves every returned route so it can be shown
// as history later. A TfL failure still leaves a row behind (status='error')
// instead of silently vanishing.
async function planJourneysForUser(userId, from, to) {
    const { rows } = await pool.query(
        `INSERT INTO journey_requests (user_id, origin_text, destination_text, status)
         VALUES ($1, $2, $3, 'pending')
         RETURNING id`,
        [userId, from, to]
    );
    const journeyRequestId = rows[0].id;

    let journeys;
    try {
        journeys = await planJourneys(from, to);
    } catch (err) {
        await pool.query(`UPDATE journey_requests SET status = 'error' WHERE id = $1`, [journeyRequestId]);
        throw err;
    }

    if (journeys.length > 0) {
        await persistJourneys(journeyRequestId, journeys);
    } else {
        await pool.query(`UPDATE journey_requests SET status = 'complete' WHERE id = $1`, [journeyRequestId]);
    }

    return { journeyRequestId, journeys };
}

// Lists the user's past journey requests
async function getJourneyHistoryForUser(userId, limit = 20) {
    const { rows: requests } = await pool.query(
        `SELECT id, origin_text, destination_text, status, requested_at
         FROM journey_requests
         WHERE user_id = $1
         ORDER BY requested_at DESC
         LIMIT $2`,
        [userId, limit]
    );

    if (requests.length === 0) return [];

    const requestIds = requests.map((r) => r.id);
    const { rows: routes } = await pool.query(
        `SELECT
            ro.journey_request_id, ro.id AS route_option_id, ro.tfl_route_index,
            ro.summary, ro.total_duration_seconds, ro.total_walking_distance_m,
            ro.walking_leg_count, ro.is_fastest, ro.is_recommended,
            rs.crime_count, rs.total_walking_distance_km, rs.exposure_per_km, rs.exposure_reduction_pct
         FROM route_options ro
         LEFT JOIN route_scores rs ON rs.route_option_id = ro.id
         WHERE ro.journey_request_id = ANY($1)
         ORDER BY ro.journey_request_id, ro.tfl_route_index`,
        [requestIds]
    );

    const routesByRequest = new Map();
    for (const route of routes) {
        const list = routesByRequest.get(route.journey_request_id) || [];
        list.push({
            routeOptionId: route.route_option_id,
            tflRouteIndex: route.tfl_route_index,
            summary: route.summary,
            totalDurationSeconds: route.total_duration_seconds,
            totalWalkingDistanceM: route.total_walking_distance_m,
            walkingLegCount: route.walking_leg_count,
            isFastest: route.is_fastest,
            isRecommended: route.is_recommended,
            crimeCount: route.crime_count,
            totalWalkingDistanceKm: route.total_walking_distance_km,
            exposurePerKm: route.exposure_per_km,
            exposureReductionPct: route.exposure_reduction_pct,
        });
        routesByRequest.set(route.journey_request_id, list);
    }

    return requests.map((r) => ({
        journeyRequestId: r.id,
        originText: r.origin_text,
        destinationText: r.destination_text,
        status: r.status,
        requestedAt: r.requested_at,
        routes: routesByRequest.get(r.id) || [],
    }));
}

module.exports = {
    planJourneys,
    planJourneysForUser,
    getJourneyHistoryForUser,
    TflConfigError,
    TflTimeoutError,
    TflUpstreamError,
};
