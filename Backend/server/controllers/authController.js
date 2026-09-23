const authService = require("../services/authService")

// email and password rules
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const MAX_EMAIL_LENGTH = 254; 
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 72;

// lowercase the email so Ana@x.com and ana@x.com are the same account
function normalizeEmail(email) {
    return typeof email === "string" ? email.trim().toLowerCase() : email;
}

// returns an error message, or null if everything is ok
function validateCredentials(email, password){
    if(typeof email !== "string" || email.length > MAX_EMAIL_LENGTH || !EMAIL_RE.test(email)){
        return "a valid email is required"
    }
    if(typeof password !== "string" || password.length < MIN_PASSWORD_LENGTH){
        return `password must be at least ${MIN_PASSWORD_LENGTH} characters`
    }
    if (password.length > MAX_PASSWORD_LENGTH){
        return `password must be at most ${MAX_PASSWORD_LENGTH} characters`
    }
    return null;
}

// POST register, body: {email, password}
async function register(req, res){
    const body = req.body || {};
    const email = normalizeEmail(body.email);
    const {password} = body;

    const validationError = validateCredentials(email, password);
    if (validationError) {
        return res.status(400).json({ error: validationError })
    }

    try {
        const user = await authService.register(email, password)
        res.status(201).json({ user })
    }catch (err){
        // email already in the users table
        if (err.code === "23505"){
            return res.status(409).json({ error: "account with that email already exists" })
        }
        console.error(err);
        res.status(500).json({ error: "failed to register"})
    }
}

// POST login, Body: {email, password}
async function login(req,res){
    const body = req.body || {}
    const email = normalizeEmail(body.email)
    const {password} = body

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
