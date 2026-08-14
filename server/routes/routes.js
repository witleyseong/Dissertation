const express = require("express");
const { getExposure } = require("../controllers/routesController");
const requireAuth = require("../middleware/auth");

const router = express.Router();

// Protects the exposure endpoint with JWT authentication before passing
// the request to the controller with req.user available.
router.post("/exposure", requireAuth, getExposure);

module.exports = router;
