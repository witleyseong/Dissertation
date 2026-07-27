const bcrypt = require("bcrypt")
const jwt = require("jsonwebtoken")
const pool = require("../db")

// bcrypt hashing of 10
const SALT_ROUNDS = 10;

async function register(email, password) {
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await pool.query(
        `INSERT INTO users (email, password_hash)
        VALUES ($1, $2)
        RETURNING id, email, plan, created_at
        `,
        [email, passwordHash]
    );
    return result.rows[0];
}

// Looks up the user by email, compares the given password against the
// stored bcrypt hash, and if it matches, signs a JWT containing the user's
// id and email. Returns null if the email doesn't exist or the password
// is wrong — the controller decides how to respond (401), not this service.
async function login(email, password){
    const result = await pool.query(
        `SELECT id, email, password_hash,plan FROM users WHERE email = $1`,
        [email]
    );
    const user = result.rows[0]
    if (!user) return null;

    const passwordMatches = await bcrypt.compare(password, user.password_hash)
    if (!passwordMatches) return null;

    const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expriesIn: "7d"}
    );

    return { token, user: {id: user.id, email: user.email, plan: user.plan} }
}

module.exports = { register, login};

