-- add the account layer
-- Additive: brings an existing database up to schema.sql without
-- dropping the imported crime records.
 
BEGIN;
 
CREATE TABLE IF NOT EXISTS users (
    id            bigserial PRIMARY KEY,
    email         varchar(255) NOT NULL,
    password_hash text         NOT NULL,
    plan          varchar(20)  NOT NULL DEFAULT 'free',
    created_at    timestamptz  NOT NULL DEFAULT now()
);
 
-- Case-insensitive uniqueness (FR-01).
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users (LOWER(email));
 
-- Link each journey request to the account that submitted it (FR-07).
ALTER TABLE journey_requests ADD COLUMN IF NOT EXISTS user_id bigint;
DELETE FROM journey_requests WHERE user_id IS NULL;
ALTER TABLE journey_requests ALTER COLUMN user_id SET NOT NULL;
 
ALTER TABLE journey_requests DROP CONSTRAINT IF EXISTS journey_requests_user_id_fkey;
ALTER TABLE journey_requests ADD CONSTRAINT journey_requests_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
 
CREATE INDEX IF NOT EXISTS journey_requests_user_idx ON journey_requests (user_id);
 
COMMIT;
 