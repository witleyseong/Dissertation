const express = require("express");
const { getJourneys } = require("../controllers/journeyController");
const requireAuth = require("../middleware/auth");

const router = express.Router();

// Protects the journey endpoint with JWT authentication before passing
// the request to the controller with req.user available.
router.post("/", requireAuth, getJourneys);

module.exports = router;
