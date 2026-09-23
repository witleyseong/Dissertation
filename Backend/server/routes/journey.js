const express = require("express");
const { getJourneys, getHistory } = require("../controllers/journeyController");
const requireAuth = require("../middleware/auth");

const router = express.Router();

// needs a token
router.post("/", requireAuth, getJourneys);

// past journeys of the logged in user
router.get("/history", requireAuth, getHistory);

module.exports = router;
