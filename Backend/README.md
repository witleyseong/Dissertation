# SafeWay London - Backend

This is the backend for my final year project, SafeWay London. It's a REST API that suggests walking/transit routes around London and tells you how "exposed" each route is to crime, based on real UK police crime data.

## What it does

- User registration/login with JWT
- Get journey options between two points (calls the public TfL Journey API)
- Score each route based on nearby crime data (using PostGIS)
- Save journey history per user
- A standalone endpoint to check exposure for any custom walking route

## Tech stack

- Node.js + Express
- PostgreSQL + PostGIS (for the geo/spatial queries)
- bcrypt (password hashing)
- jsonwebtoken (JWT auth)
- helmet + cors + express-rate-limit (basic security stuff)
- Docker (just for running the database locally)

## Project structure

```
server/
├── index.js              # app entrypoint, sets up middleware and routes
├── db.js                 # postgres connection pool
├── controllers/          # handles requests, calls services
├── routes/                # express route definitions
├── services/              # actual logic (auth, journeys, exposure calculation)
├── middleware/            # JWT auth check
├── config/                 # exposure calculation settings (buffer radius, categories, etc)
└── scripts/                # one-off scripts (e.g. threshold calibration)

schema.sql            # full database schema
migrations/            # migration to add users table to an existing db
docker-compose.yml   # spins up a Postgres + PostGIS container, creates the tables and loads the crime data
db/crime_db/          # UK police street-level crime CSVs (data.police.uk), one folder per month
db/load-crimes.sh     # loads the CSVs into the crimes table (runs automatically on first start)
import.sh              # re-runs the crime import on an already running database (optional)
```

## Setup

The backend and the iOS app (in the `Frontend` folder) are designed to run together: the API on `http://localhost:3000` and the app in the iOS Simulator. The steps are the same on Mac and Windows.

**Before you start, you need:**

1. [Node.js 18+](https://nodejs.org/) installed (check: `node -v`).
2. [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed **and open** (the whale icon must be in the menu bar / system tray and say "running"). If Docker is closed, step 1 fails with `Cannot connect to the Docker daemon`.
3. Nothing else: no accounts, API keys or `.env` file.

Open a terminal in the `Backend/` folder and run the steps in order.

**1. Start the database** (Docker Desktop must be open)

```bash
cd Backend
docker compose up -d
```

The first time, this creates the tables and loads the crime data from `db/crime_db/` (about 1.8 million records). That takes **about 2-5 minutes**, and the command returns immediately while it works in the background. Check that it is finished:

```bash
docker logs safeway-db
```

It is ready when the last lines say `PostgreSQL init process complete; ready for start up.` followed by `database system is ready to accept connections`. If you don't see that yet, wait a minute and run the command again. Later starts take a few seconds.

**2. Install and run the server** (keep this terminal open)

```bash
cd server
npm install
npm run dev
```

You should see `Server running on http://localhost:3000`. (Warnings from `npm install` about vulnerabilities or funding can be ignored.)

**3. Check that it works**

Open http://localhost:3000/api/health in a browser. It should show `"status":"ok"` and `"crimesInDatabase":1784295`.

Then start the iOS app as described in the `Frontend` README.

### If something goes wrong

| Problem | Fix |
|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop is not open. Open it, wait until it says running, repeat step 1. |
| Warning about `linux/amd64` platform (Apple Silicon Macs) | Harmless, ignore it. |
| `/api/health` shows `"database":"unreachable"` or the server can't connect | The database is still loading (step 1). Wait until `docker logs safeway-db` shows the "ready" line, then reload the page. If it still fails, restart the server (Ctrl+C, then `npm run dev`). |
| `crimesInDatabase` is `0` | The crime data did not load. Run `docker compose down -v`, then `docker compose up -d` and wait again. (This deletes the database and rebuilds it.) |
| `port 5432 is already allocated` | Another Postgres is running on this computer. Stop it, or run `docker compose down` and try again. |
| `bcrypt` error mentioning `dlopen` or code signature (Mac) | macOS Gatekeeper, not a bug. Run `xattr -cr node_modules/bcrypt` inside `server/` and start again. |
| Port 3000 already in use | Close whatever program is using it (often another copy of this server) and run `npm run dev` again. |

To stop everything: press Ctrl+C in the server terminal, then `docker compose down` (your data is kept; `docker compose down -v` deletes it).

## API endpoints

| Method | Endpoint | Auth needed? | What it does |
|---|---|---|---|
| POST | `/api/auth/register` | No | Create an account (`{ email, password }`) |
| POST | `/api/auth/login` | No | Log in, returns a JWT token |
| POST | `/api/journey` | Yes (Bearer token) | Get journey options + exposure scores between `from` and `to` |
| GET | `/api/journey/history` | Yes (Bearer token) | Get the logged-in user's past journeys |
| POST | `/api/routes/exposure` | Yes (Bearer token) | Get an exposure score for a custom list of coordinates |
| GET | `/api/health` | No | Check if the API and database are up, and how much crime data is loaded |

For protected routes, send the token like this:

```
Authorization: Bearer <your-jwt-token>
```

## Database overview

The main tables are:

- `users` - accounts (email + hashed password)
- `crimes` - crime records from data.police.uk, with coordinates
- `journey_requests` - a journey a user asked for
- `route_options` - the different route choices returned for a journey
- `route_legs` - individual legs (walk/bus/tube/etc) of a route
- `route_scores` - the exposure score calculated for a route

The exposure score works by drawing a small buffer (default 50m) around each walking leg and counting how many crimes from the `crimes` table fall inside it, then dividing by the walking distance to get a "crimes per km" value.

## Known limitations

- The app runs outside Docker - only the database is containerized
