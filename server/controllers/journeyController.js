const { planJourneys, TflConfigError, TflTimeoutError, TflUpstreamError } = require("../services/journeyService");

const MAX_ADDRESS_LENGTH = 200;

function isValidAddress(value) {
    return typeof value === "string" && value.trim().length > 0 && value.trim().length <= MAX_ADDRESS_LENGTH;
}

// POST /api/journey
async function getJourneys(req, res) {
    const { from, to } = req.body;

    if (!isValidAddress(from) || !isValidAddress(to)) {
        return res.status(400).json({
            error: `from and to are required non-empty strings of at most ${MAX_ADDRESS_LENGTH} characters`,
        });
    }

    try {
        const journeys = await planJourneys(from.trim(), to.trim());
        if (journeys.length === 0) {
            return res.json({ journeys: [], message: "No routes found for these locations." });
        }
        res.json({ journeys });
    } catch (err) {
        // Logs detailed errors server-side while returning only a short,
        // predictable error message to the client.
        console.error(err);

        if (err instanceof TflConfigError) {
            return res.status(500).json({ error: "journey planning is not configured correctly on the server" });
        }
        if (err instanceof TflTimeoutError) {
            return res.status(503).json({ error: "journey planning service is temporarily unavailable, please try again" });
        }
        if (err instanceof TflUpstreamError) {
            return res.status(502).json({ error: "journey planning service returned an error" });
        }
        res.status(502).json({ error: "failed to plan journey" });
    }
}

module.exports = { getJourneys };
