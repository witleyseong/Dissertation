const jwt = require("jsonwebtoken")

// checks the Bearer token and puts the user in req.user, otherwise 401
function requireAuth(req, res, next) {
    const header = req.headers.authorization;

    if (!header || !header.startsWith("Bearer ")){
        return res.status(401).json({ error: "missing Authorization header"})
    }

    const token = header.slice("Bearer ".length)

    try{
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        req.user = { id: payload.userId, email: payload.email }
        next();
    }catch (err){
        return res.status(401).json({ error: "invalid or expired token"})
    }
}

module.exports = requireAuth;