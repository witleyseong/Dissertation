-- ============================================================
-- SafeWay London — full database schema (matches the ERD)
-- PostgreSQL + PostGIS. Safe to re-run (drops and recreates).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- Drop existing tables first. CASCADE clears foreign-key dependencies.
DROP TABLE IF EXISTS route_scores        CASCADE;
DROP TABLE IF EXISTS route_legs          CASCADE;
DROP TABLE IF EXISTS route_options       CASCADE;
DROP TABLE IF EXISTS journey_requests    CASCADE;
DROP TABLE IF EXISTS evaluation_journeys CASCADE;
DROP TABLE IF EXISTS tfl_api_cache       CASCADE;
DROP TABLE IF EXISTS crimes              CASCADE;

-- ------------------------------------------------------------
-- 1. crimes  (no foreign key — matched to legs spatially)
-- ------------------------------------------------------------
CREATE TABLE crimes (
    id                bigserial PRIMARY KEY,
    external_crime_id varchar(120) UNIQUE,   -- data.police.uk persistent_id
    category          varchar(80),           -- e.g. anti-social-behaviour
    month             varchar(7),            -- YYYY-MM
    latitude          float8,
    longitude         float8,
    location_approx   text,                  -- e.g. On or near High Street
    geom              geometry(Point, 4326)
);
CREATE INDEX crimes_geom_gix ON crimes USING GIST (geom);

-- ------------------------------------------------------------
-- 2. evaluation_journeys  (no foreign key — fixed test cases)
-- ------------------------------------------------------------
CREATE TABLE evaluation_journeys (
    id               bigserial PRIMARY KEY,
    name             varchar(120),           -- fixture label
    origin_text      text,
    destination_text text,
    origin_lat       float8,
    origin_lng       float8,
    dest_lat         float8,
    dest_lng         float8,
    expected_notes   text,                   -- what this fixture demonstrates
    created_at       timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- 3. journey_requests  (FK -> evaluation_journeys, nullable)
-- ------------------------------------------------------------
CREATE TABLE journey_requests (
    id                    bigserial PRIMARY KEY,
    origin_text           text,               -- raw user input
    destination_text      text,               -- raw user input
    origin_lat            float8,             -- resolved WGS84
    origin_lng            float8,
    dest_lat              float8,
    dest_lng              float8,
    status                varchar(20),        -- pending|complete|ambiguous|error
    evaluation_journey_id bigint REFERENCES evaluation_journeys(id),
    requested_at          timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- 4. route_options  (FK -> journey_requests)
-- ------------------------------------------------------------
CREATE TABLE route_options (
    id                       bigserial PRIMARY KEY,
    journey_request_id       bigint NOT NULL REFERENCES journey_requests(id) ON DELETE CASCADE,
    tfl_route_index          int,             -- index within TfL response
    summary                  text,            -- human-readable summary
    total_duration_seconds   int,
    total_walking_distance_m float8,
    walking_leg_count        int,
    is_fastest               boolean DEFAULT false,
    is_recommended           boolean DEFAULT false,  -- lower-exposure alternative
    created_at               timestamptz DEFAULT now()
);
CREATE INDEX route_options_jr_idx ON route_options (journey_request_id);

-- ------------------------------------------------------------
-- 5. route_legs  (FK -> route_options)
-- ------------------------------------------------------------
CREATE TABLE route_legs (
    id               bigserial PRIMARY KEY,
    route_option_id  bigint NOT NULL REFERENCES route_options(id) ON DELETE CASCADE,
    leg_order        int,                     -- 0-based sequence
    mode             varchar(20),             -- walking|tube|bus|rail|...
    duration_seconds int,
    distance_m       float8,
    instruction      text,                    -- turn-by-turn text
    geom             geometry(LineString, 4326)
);
CREATE INDEX route_legs_ro_idx   ON route_legs (route_option_id);
CREATE INDEX route_legs_geom_gix ON route_legs USING GIST (geom);

-- ------------------------------------------------------------
-- 6. route_scores  (FK -> route_options, one score per route)
-- ------------------------------------------------------------
CREATE TABLE route_scores (
    id                        bigserial PRIMARY KEY,
    route_option_id           bigint NOT NULL UNIQUE REFERENCES route_options(id) ON DELETE CASCADE,
    buffer_distance_m         int DEFAULT 50,
    crime_count               int,             -- distinct crimes within buffer
    total_walking_distance_km float8,
    exposure_per_km           float8,
    exposure_reduction_pct    float8,          -- vs fastest route
    calculated_at             timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- 7. tfl_api_cache  (no foreign key — infrastructure)
-- ------------------------------------------------------------
CREATE TABLE tfl_api_cache (
    id           bigserial PRIMARY KEY,
    request_hash varchar(64) UNIQUE,           -- sha256 of normalised params
    request_url  text,
    raw_response jsonb,                         -- verbatim TfL payload
    fetched_at   timestamptz DEFAULT now(),
    expires_at   timestamptz
);
