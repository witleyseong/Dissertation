const pool = require("../db")
const { CRIME_DATA_EARLIEST_MONTH, CRIME_DATA_LATEST_MONTH } = require("../config/exposureConfig")

// COUNT(*) on the crimes table is slow, so keep the result for a while
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

// simple check that the db answers
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
        // dates come from the config, no need to query them
        crimeDataStart: CRIME_DATA_EARLIEST_MONTH,
        crimeDataEnd: CRIME_DATA_LATEST_MONTH,
    }
}


module.exports = { getHealthMetadata }