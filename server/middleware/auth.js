const jwt = require("jsonwebtoken")


// Verifies the Bearer JWT token and attaches the decoded user data to req.user.
// Invalid or missing tokens send 401
function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    
    if (!header || !header.startsWith("Bearer ")){
        return res.status(401).json({ error: " missing Authorization header"})
    }

    const token = header.slice("Bearer ".length)

    try{
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        req.user = { id: payload.userId, email: payload.email }
        next();
    }catch (err){
        return res.status(401).json({ error: "invalid  or expiered token"})
    }
}

module.exports = requireAuth;