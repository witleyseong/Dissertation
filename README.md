# SafeWay London

Final year project. SafeWay London is an iOS app, backed by a Node.js API, that compares public transport routes across London by how much **historical recorded crime** their walking sections pass near.

The app does not predict safety. It compares past police-recorded crime (from [data.police.uk](https://data.police.uk/)), so it always talks about "exposure" and never about "safe", "dangerous" or "risk".

## How it works

1. The user searches for a journey between two places in London in the iOS app.
2. The backend gets the route options from the public [TfL Journey Planner API](https://api.tfl.gov.uk/).
3. For every walking leg, PostGIS draws a buffer (50 m by default) around the path and counts the recorded crimes inside it.
4. The count is normalised by walking distance (crimes per km), and each route gets an exposure band: lower, moderate or higher.
5. The app shows the routes side by side by travel time and exposure, draws them on a map and can follow the user during navigation.

## Repository structure

```
.
├── Backend/     Node.js + Express REST API, PostgreSQL/PostGIS database (Docker)
└── Frontend/    iOS app in Swift / SwiftUI (Xcode project)
```

Each folder has its own README with full details:

- [Backend/README.md](Backend/README.md): API endpoints, database schema, setup and troubleshooting
- [Frontend/README.md](Frontend/README.md): app features, project structure and how to run it in the simulator

## Tech stack

| Part | Technologies |
|---|---|
| iOS app | Swift, SwiftUI (MVVM with `@Observable`), MapKit, CoreLocation, Keychain, `URLSession` async/await. No third-party libraries. |
| API | Node.js, Express 5, JWT auth, bcrypt, helmet, CORS, express-rate-limit |
| Database | PostgreSQL 16 + PostGIS 3.4, running in Docker |
| Data | TfL Journey Planner API, UK police street-level crime data (Metropolitan Police, June 2023 onwards) |

## Quick start

**Requirements**

- Node.js 18+
- Docker Desktop (open and running)
- A Mac with Xcode 16+ for the iOS app (iOS 17+ simulator)

**1. Crime data**

The crime CSV files are about 800 MB, so they are not stored in this repository. Download the street-level crime data for the **Metropolitan Police Service** from [data.police.uk/data](https://data.police.uk/data/) and extract the monthly folders into `Backend/db/crime_db/`, so the layout looks like this:

```
Backend/db/crime_db/2023-06/2023-06-metropolitan-street.csv
Backend/db/crime_db/2023-07/2023-07-metropolitan-street.csv
...
```

**2. Backend**

```bash
cd Backend
docker compose up -d     # creates the database and loads the crime data (first run takes 2-5 min)
cd server
npm install
npm run dev              # API on http://localhost:3000
```

Check http://localhost:3000/api/health. It should return `"status":"ok"` and the number of crimes loaded.

No `.env` file or API keys are needed to run locally. The optional settings are listed in [Backend/server/.env.example](Backend/server/.env.example).

**3. iOS app**

1. Open `Frontend/SawayLondon.xcodeproj` in Xcode.
2. Choose an iPhone simulator (iOS 17 or later) and press **Cmd+R**.
3. Create an account, then search for a journey, for example `Victoria Station` to `Liverpool Street Station`.

The simulator's default location is in the USA. To use "Current Location", set a London location in **Features > Location > Custom Location** (latitude `51.5152`, longitude `-0.1419`).

## API overview

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | No | Create an account |
| POST | `/api/auth/login` | No | Log in and receive a JWT |
| POST | `/api/journey` | Yes | Journey options with exposure scores |
| GET | `/api/journey/history` | Yes | The user's past journeys |
| POST | `/api/routes/exposure` | Yes | Exposure score for a custom list of coordinates |
| GET | `/api/health` | No | API and database status |

## Limitations

- Exposure is based only on **recorded** crime. Many crimes are never reported, and police coordinates are anonymised to a nearby point, so the scores are an approximation.
- Only the walking legs are scored. Time spent on trains or buses is not.
- The API runs over plain HTTP on localhost. A real deployment would need HTTPS and a proper `JWT_SECRET`.
- Payments and subscriptions are not implemented. `PaywallView` is a placeholder.

## Author

Witley Seong, final year project.
