// postgres connection pool
require("./config/env");
const { Pool } = require("pg");

// the pool reuses connections instead of opening a new one for every query
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
})

module.exports = pool;