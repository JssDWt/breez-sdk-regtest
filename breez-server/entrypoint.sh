#!/usr/bin/env bash

set -m

until psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER" -c "select 1"; do
  echo "Waiting for postgres server to start..."
  sleep 1
done

echo "Migrating database"
migrate -source=file://migrations -database="$DATABASE_URL" up
echo "Database migrated"

echo "Updating api_keys"
psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER"  -c 'DELETE FROM api_keys;'
psql -h "$POSTGRES_HOST" -d "$POSTGRES_DB" -U "$POSTGRES_USER"  << SQL
INSERT INTO api_keys (api_key, api_user, lsp_ids)
VALUES ('$SDK_API_KEY', 'sdk', '["$LSP_ID"]'::json);
SQL
echo "api_keys updated"

echo "Breez server starting"
server
