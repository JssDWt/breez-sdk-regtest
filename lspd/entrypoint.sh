#!/usr/bin/env bash

set -m

until psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER" -c "select 1"; do
  echo "Waiting for postgres server to start..."
  sleep 1
done

echo "Migrating database"
migrate -source=file://migrations -database="$DATABASE_URL" up
echo "Database migrated"

echo "Updating new_channel_params"
psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER"  -c 'DELETE FROM new_channel_params;'
psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER"  << SQL
INSERT INTO new_channel_params (validity, params, token)
VALUES
    (3600, '{"min_msat": "1000000", "proportional": 7500, "max_idle_time": 4320, "max_client_to_self_delay": 432}', '$LSPD_TOKEN'),
    (259200, '{"min_msat": "1100000", "proportional": 7500, "max_idle_time": 4320, "max_client_to_self_delay": 432}', '$LSPD_TOKEN');
SQL
echo "new_channel_params updated"


until [ -f "/data/.lightning/regtest/server.pem" ]
do
    echo "Waiting for core-lightning to generate certificates"
     sleep 1
done

echo "LSPD starting"
lspd
