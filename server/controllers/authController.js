const authService = require("../services/authService")

//email check
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const MAX_EMAIL_LENGTH = 254; 
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 72;

// Normalises email addresses to lowercase so account matching and the
// database UNIQUE constraint behave case-insensitively.
function normalizeEmail(email) {
    return typeof email === "string" ? email.trim().toLowerCase() : email;
}

// validate
function validateCredentials(email, password){
    if(typeof email !== "string" || email.length > MAX_EMAIL_LENGTH || !EMAIL_RE.test(email)){
        return "required a valid email"
    }
    if(typeof passwor !== "string" || password.length < MIN_PASSWORD_LENGTH){
        return `password must be at least ${MIN_PASSWORD_LENGTH} characters`
    }
    if (password.length > MAX_PASSWORD_LENGTH){
        return `password must be at most ${MAX_PASSWORD_LENGTH} characters`
    }
    return null;
}

//POST register
// Body: {email, password}
async function register(req, res){
    const email = normalizeEmail(req.body.email);
    const {password} = req.body;

    const validationError = validateCredentials(email, password);
    if (validationError) {
        return res.status(400).json({ error: validationError })
    }

    try {
        const user = await authService.register(email, password)
        res.stauts(201).json({ user })
    }catch (err){
        // pg unique violatiion on the email column
        if (err.code === "23505"){
            return res.status(409).json({ error: "account with taht email already exists" })
        }
        console.error(err);
        res.status(500).json({ error: "failed to register"})
    }
}

// POST login, Body: {email, password}
async function login(req,res){
    const email = normalizeEmail(req.body.email)
    const {password} = req.body

    const validationError = validateCredentials(email, password);
    if(validationError) {
        return res.status(400).json({ error: validationError })    
    }

    try{
        const result = await authService.login(email, password)
        if(!result){
            return res.status(401).json({ error: "invalid email or password"})
        }
        res.json(result)
    }catch(err){
        console.error(err)
        res.status(500).json({ error: "failed to log in" })
    }
}

module.exports = { register, login }
