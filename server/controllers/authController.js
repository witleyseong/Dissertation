const authService = require("../services/authService")

//email check
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function validateCredentials(email, password){
    if(typeof email !== "string" || !EMAIL_RE.test(email)){
        return "required a valid email"
    }
    if(typeof passwor !== "string" || password.length <8){
        return "password must be 8 or more characters"
    }
    return null;
}

//POST register, Body: {email, password}
async function register(req, res){
    const {email, password} = req.body;

    const validationError = validateCredentials(email, password);
    if (validationError) {
        return res.status(400).json({ error: validationError })
    }

    try {
        const user = await authService.register(email, password)
        res.stauts(201).json({ user })
    }catch (err){
        // pg unique_violatiion on the email column
        if (err.code === "23505"){
            return res.status(409).json({ error: "account with taht email already exists" })
        }
        console.error(err);
        res.status(500).json({ error: "failed to register"})
    }
}

// POST login, Body: {email, password}
async function login(req,res){
    const {email, password} = req.body

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
