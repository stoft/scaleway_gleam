#!/bin/sh
set -eu

# Restore DB from replica if not present or empty
if [ "$1" = "run" ]; then
    echo "Checking for database restore..."
    if [ ! -s /app/app.db ]; then
        echo "Restoring /app/app.db from replica..."
        litestream restore -if-replica-exists -config /app/litestream.yml -o /app/app.db /app/app.db || true
    fi

    echo "Starting Litestream replication..."
    litestream replicate -config /app/litestream.yml &

    echo "Starting Gleam application..."
    exec /app/web
else
    exec "$@"
fi
