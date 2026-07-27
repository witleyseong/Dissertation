const jwt = require("jsonwebtoken")

// Express middleware: reads "Authorization: Bearer <token>", verifies it
// with the JWT secret, and attaches the decoded payload to req.user.
// Any route that uses this middleware runs `next()` only for valid tokens;
// otherwise it rejects with 401 before the route handler ever runs.

function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    
    if (!header || !header.startsWith("Bearer ")){
        return res.status(401).json({ error: " missing Authorization header"})
    }

    const token = header.slice("Bearer ". length)

    try{
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        req.user = {id: payload,userId, email: payload.email }
        next();
    }catch (err){
        return res.status(401).json({ error: "invalid  or expiered token"})
    }
}

module.exports = requireAuth;