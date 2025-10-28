# Scaleway Gleam Hanko

This is a Gleam example project with Hanko authentication deployed to Scaleway Serverless Containers.

Minimum Scaleway Serverless Container configuration needed to work for this project with scale to zero:

```
mCPU=250
MEMORY=256
```

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
make run-watch  # Run with file watching
```

## Database Replication with Litestream

This project uses [Litestream](https://litestream.io/) for SQLite database replication to Scaleway Object Storage.

### Setup

1. **Configure Scaleway Object Storage credentials** in `litestream.yml`:

   ```yaml
   access-key-id: YOUR_SCALEWAY_ACCESS_KEY_ID
   secret-access-key: YOUR_SCALEWAY_SECRET_ACCESS_KEY
   ```

2. **Update the bucket and region** in `litestream.yml`:
   ```yaml
   url: s3://YOUR_BUCKET_NAME/app.db
   region: fr-par # Replace with your Scaleway region
   ```

### Commands

```sh
# Run with Litestream replication
make run-with-litestream

# Restore database from backup
make restore-db

# Start replication only
make replicate-db

# Stop Litestream
make stop-litestream
```

### Docker

The Docker image includes Litestream and will automatically start replication when the container runs.

### Environment

Create a `.env` file and set values:

```
HANKO_API_URL=https://<your-project>.hanko.io
HANKO_SESSION_COOKIE_NAME=hanko
PORT=3000
SECRET_KEY_BASE=this-is-a-secret-key-that-must-be-at-least-64-characters-long-for-security-purposes
```
