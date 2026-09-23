require("./config/env")
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
app.use(cors())
app.use(express.json({ limit: "1mb" }))

// max 20 login/register requests per 15 minutes
const authRateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "too many auth requests, please try again later" },
})

app.use("/api/routes", routesRouter)
app.use("/api/auth", authRateLimiter, authRouter)
app.use("/api/journey", journeyRouter)

// checks the db is up and how many crimes are loaded

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
        // old name, the iOS app still reads this one
        crimes_in_db: metadata.crimesInDatabase,
    })
});

// only start listening when this file is run directly
if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`Server running on http://localhost:${PORT}`);
    });
}

module.exports = app;
