// loads server/.env if there is one, otherwise uses defaults
// so the project runs without any setup
require("dotenv").config();

// same login as docker-compose.yml
process.env.DATABASE_URL ||= "postgres://safeway:safeway@localhost:5432/safeway";

// secret for the login tokens, fine for running locally
// (use a .env with your own if this ever gets deployed)
if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = "safeway-london-local-dev-secret";
    console.warn("JWT_SECRET not set, using the default one");
}
