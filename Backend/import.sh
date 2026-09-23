#!/bin/bash
# reloads the crime CSVs into the running database
# not needed the first time, docker compose up already does it
docker exec safeway-db bash /docker-entrypoint-initdb.d/02-load-crimes.sh
