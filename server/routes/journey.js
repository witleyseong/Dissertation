const express = require("express");
const { getJourneys, getHistory } = require("../controllers/journeyController");
const requireAuth = require("../middleware/auth");

const router = express.Router();

// Protects the journey endpoint with JWT authentication before passing
// the request to the controller with req.user available.
router.post("/", requireAuth, getJourneys);

// Lists the authenticated user's past journey requests and their saved routes.
router.get("/history", requireAuth, getHistory);

module.exports = router;
