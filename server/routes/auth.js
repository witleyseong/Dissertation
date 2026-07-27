const express = require("express")
const {register, login } = require("../controllers/authController")

const route = express.Router();

// post register to authcontroller.register
router.post("/register", register)

// post login to authController.login
router.post("/login", login)

module.exports = router