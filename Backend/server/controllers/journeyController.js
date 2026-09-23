const { planJourneysForUser, getJourneyHistoryForUser, TflConfigError, TflTimeoutError, TflUpstreamError, TflDisambiguationError } = require("../services/journeyService");

const MAX_ADDRESS_LENGTH = 200;

function isValidAddress(value) {
    return typeof value === "string" && value.trim().length > 0 && value.trim().length <= MAX_ADDRESS_LENGTH;
}

// POST /api/journey
async function getJourneys(req, res) {
    const { from, to } = req.body || {};

    if (!isValidAddress(from) || !isValidAddress(to)) {
        return res.status(400).json({
            error: `from and to are required non-empty strings of at most ${MAX_ADDRESS_LENGTH} characters`,
        });
    }

    try {
        const { journeyRequestId, journeys } = await planJourneysForUser(req.user.id, from.trim(), to.trim());
        if (journeys.length === 0) {
            return res.json({ journeyRequestId, journeys: [], message: "No routes found for these locations." });
        }
        res.json({ journeyRequestId, journeys });
    } catch (err) {
        // full error goes to the console, the app only gets a short message
        console.error(err);

        if (err instanceof TflDisambiguationError) {
            // not an error: TfL found several places with that name,
            // so send the options back and let the user pick one
            return res.json({
                journeys: [],
                message: "Multiple locations matched your search, please choose one.",
                disambiguation: err.disambiguation,
            });
        }
        if (err instanceof TflConfigError) {
            return res.status(500).json({ error: "journey planning is not configured correctly on the server" });
        }
        if (err instanceof TflTimeoutError) {
            return res.status(503).json({ error: "journey planning service is temporarily unavailable, please try again" });
        }
        if (err instanceof TflUpstreamError) {
            return res.status(502).json({ error: "journey planning service returned an error" });
        }
        // token is valid but the user is gone (database was reset)
        if (err.code === "23503" && err.constraint === "journey_requests_user_id_fkey") {
            return res.status(401).json({ error: "session no longer valid, please log in again" });
        }
        res.status(500).json({ error: "failed to plan journey" });
    }
}

// GET /api/journey/history
async function getHistory(req, res) {
    try {
        const history = await getJourneyHistoryForUser(req.user.id);
        res.json({ history });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "failed to load journey history" });
    }
}

module.exports = { getJourneys, getHistory };
