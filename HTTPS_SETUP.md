# HTTPS Setup

This project now uses Caddy as the public HTTPS reverse proxy in front of the
FastAPI container.

## How it works

- `caddy` listens on ports `80` and `443`
- Caddy automatically redirects HTTP to HTTPS
- Caddy automatically provisions and renews TLS certificates
- `api` stays internal on the Docker network and is no longer exposed directly

Traffic flow:

`Client -> HTTPS -> Caddy -> http://api:8000`

## Before you start

1. Point a public DNS record at this server.
2. Set `DOMAIN` in `.env` to that real domain.
3. Make sure ports `80` and `443` are open on the server firewall.

## Deploy

```bash
docker compose up -d --build
```

## Flutter app

Use the HTTPS domain in the app:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.example.com
```

## Notes

- Keep the database private. It should not be reachable from the public internet.
- The API container still serves plain HTTP internally, which is normal when a
  reverse proxy handles TLS.
