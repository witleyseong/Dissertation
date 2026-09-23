const express = require("express");
const { getExposure } = require("../controllers/routesController");
const requireAuth = require("../middleware/auth");

const router = express.Router();

// needs a token
router.post("/exposure", requireAuth, getExposure);

module.exports = router;
