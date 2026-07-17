// this pool is to connect with Postgres
require("dotenv").config();
console.log("DB URL:", process.env.DATABASE_URL);
const { Pool } = require("pg");

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
})

module.exports = pool;