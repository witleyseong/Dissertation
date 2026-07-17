const express = require("express")
const cors = require("cors")
const pool = require("./db")

const app = express()
app.use(cors())
app.use(express.json())

app.get("/api/health", async (req, res) => {
    try{
        const result = await pool.query("SELECT COUNT(*) FROM crimes");
            res.json({
                status: "ok",
                crimes_in_db: Number(result.rows[0].count),
            });
    }catch(err){
        console.error(err);
        res.status(503).json({ status: "error", message: "database not reachable" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
