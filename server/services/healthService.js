const pool = require("../db")
const { CRIME_DATA_EARLIEST_MONTH, CRIME_DATA_LATEST_MONTH } = require("../config/exposureConfig")

// Caches the database row count so frequent health checks do not repeatedly
// run an expensive COUNT(*) query over the full dataset.
const CACHE_TTL_MS = 5 * 60 * 1000 // = 5 minutes

let cache = { crimesInDatabase: null, fetchedAt: 0 }

async function getCrimeCount() {
    const isStale = Date.now() - cache.fetchedAt > CACHE_TTL_MS;
    if (!isStale && cache.crimesInDatabase !== null) {
        return cache.crimesInDatabase;
    }
    const { rows } = await pool.query("SELECT COUNT(*) FROM crimes")
    cache = { crimesInDatabase: Number(rows[0].count), fetchedAt: Date.now() }
    return cache.crimesInDatabase;
}

// Performs a fast database connectivity check without querying the crimes table.
async function isDatabaseReachable() {
    try {
        await pool.query("SELECT 1")
        return true;
    } catch {
        return false;
    }
}

async function getHealthMetadata() {
    const databaseReachable = await isDatabaseReachable();
    if (!databaseReachable) {
        return { databaseReachable }
    }

    const crimesInDatabase = await getCrimeCount();
    return {
        databaseReachable,
        crimesInDatabase,
        // Uses fixed configuration values for the crime data date range instead
        // of querying the database for the earliest and latest months.
        crimeDataStart: CRIME_DATA_EARLIEST_MONTH,
        crimeDataEnd: CRIME_DATA_LATEST_MONTH,
    }
}


module.exports = { getHealthMetadata }