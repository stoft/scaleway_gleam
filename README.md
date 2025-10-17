# Scaleway Gleam Hanko

This is a Gleam example project with Hanko authentication deployed to Scaleway Serverless Containers.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

### Environment

Create a `.env` file and set values:

```
HANKO_API_URL=https://<your-project>.hanko.io
HANKO_SESSION_COOKIE_NAME=hanko
PORT=3000
SECRET_KEY_BASE=this-is-a-secret-key-that-must-be-at-least-64-characters-long-for-security-purposes
```
