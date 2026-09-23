const express = require("express")
const {register, login } = require("../controllers/authController")

const router = express.Router();

// create account
router.post("/register", register)

// log in
router.post("/login", login)

module.exports = router