const os = require("os")
const express = require("express")
const cors = require("cors")
const helmet = require("helmet")
const rateLimit = require("express-rate-limit")
const routesRouter = require("./routes/routes")
const authRouter = require("./routes/auth")
const journeyRouter = require("./routes/journey")
const { getHealthMetadata } = require("./services/healthService")

const app = express()
app.use(helmet())


// Uses a configurable CORS allowlist in production while allowing open
// access during local development when no origins are configured.
const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS
    ? process.env.CORS_ALLOWED_ORIGINS.split(",").map((origin) => origin.trim())
    : null
if (!allowedOrigins) {
    console.warn("CORS_ALLOWED_ORIGINS is not set — allowing requests from any origin. Set it before deploying to production.")
}
app.use(cors(allowedOrigins ? { origin: allowedOrigins } : {}))

// Limits JSON request bodies to 1MB, safely covering legitimate API payloads
// while preventing excessively large requests.
app.use(express.json({ limit: "1mb" }))

// Rate-limits login and registration to reduce brute-force attempts,
// while remaining disabled during automated tests.
const authRateLimiter = process.env.NODE_ENV === "test"
    ? (req, res, next) => next()
    : rateLimit({
        windowMs: 15 * 60 * 1000,
        max: 20,
        standardHeaders: true,
        legacyHeaders: false,
        message: { error: "too many auth requests, please try again later" },
    })

// Mounts the routes from routes.js under /api/routes,
// including the JWT-protected POST /api/routes/exposure endpoint.
app.use("/api/routes", routesRouter)

// Mounts the authentication routes under /api/auth,
// including the register and login endpoints.
app.use("/api/auth", authRateLimiter, authRouter)

// Mounts journey routes under /api/journey, including the endpoint that
// retrieves TfL journeys and calculates walking-leg crime exposure.
app.use("/api/journey", journeyRouter)

app.get("/api/health", async (req, res) => {
    const metadata = await getHealthMetadata()
    if (!metadata.databaseReachable) {
        return res.status(503).json({ status: "error", database: "unreachable" })
    }
    res.json({
        status: "ok",
        database: "connected",
        crimesInDatabase: metadata.crimesInDatabase,
        crimeDataStart: metadata.crimeDataStart,
        crimeDataEnd: metadata.crimeDataEnd,
        // legacy field name, kept for any existing consumer
        crimes_in_db: metadata.crimesInDatabase,
    })
});

// Finds the machine's local IPv4 address for use as the API base URL
// when testing the app from another device on the same network.
function getLanAddress() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === "IPv4" && !iface.internal) {
                return iface.address;
            }
        }
    }
    return null;
}

// Starts the server only when run directly, avoiding a real network port
// when Jest imports the app for in-process testing.
if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`Server running on http://localhost:${PORT}`);
        const lanAddress = getLanAddress();
        if (lanAddress) {
            console.log(`On WiFi network at http://${lanAddress}:${PORT}`);
        }
    });
}

module.exports = app;
