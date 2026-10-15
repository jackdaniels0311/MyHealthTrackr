# MyHealthTrackr

MyHealthTrackr is a full-stack health and nutrition tracking application built as a final-year project. It provides a mobile experience for recording meals, monitoring weight, setting nutrition goals, and receiving personalised meal recommendations.

## Features

- Secure account registration and JWT-based sign-in with refresh tokens
- Personal health profiles, weight goals, calorie targets, macronutrients, and hydration recommendations
- Daily food diary with meal and food-item logging
- Food search and barcode scanning using the Open Food Facts API
- Saved meals that can be reused and logged quickly
- Weight-history tracking with progress charts
- Personalised AI-generated meal recommendations using Google Gemini
- REST API with validation, user-scoped access control, health checks, and automatic API documentation
- Docker-based deployment with PostgreSQL and Caddy HTTPS reverse proxy support

## Technology Stack

**Mobile application**

- Flutter and Dart
- Material 3 UI
- `fl_chart` for progress visualisation
- `mobile_scanner` for barcode scanning
- Secure token storage with `flutter_secure_storage`

**Backend**

- Python and FastAPI
- PostgreSQL with SQLAlchemy
- Alembic database migrations
- Pydantic request and response validation
- JWT authentication with password hashing
- Open Food Facts and Google Gemini integrations

**Infrastructure**

- Docker and Docker Compose
- Caddy for reverse proxying and automatic HTTPS

## Project Structure

```text
.
├── api/                         # FastAPI backend, database models, services, and migrations
├── myhealthtrackr_application/  # Flutter mobile application
├── docker-compose.yml            # PostgreSQL, API, and Caddy services
├── Caddyfile                    # HTTPS reverse-proxy configuration
└── .env.example                 # Environment variable template
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10 or later
- Docker Desktop or Docker Engine with Docker Compose
- A Google Gemini API key for AI meal recommendations
- A public domain and DNS record if HTTPS deployment is required

### Configure the backend

1. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

2. Update `.env` with a strong database password, a random `JWT_SECRET`, and your Gemini API key:

   ```env
   POSTGRES_PASSWORD=replace_with_a_strong_password
   JWT_SECRET=replace_with_a_random_secret_at_least_32_characters_long
   GEMINI_API_KEY=your_gemini_api_key
   ```

3. Start the database and API services:

   ```bash
   docker compose up -d --build db api
   ```

4. Apply database migrations:

   ```bash
   docker compose exec api alembic upgrade head
   ```

The API is available locally at `http://127.0.0.1:8000`. FastAPI's interactive documentation is available at `/docs`.

### Run the Flutter application

Install dependencies and launch the app:

```bash
cd myhealthtrackr_application
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For an Android emulator, use `http://10.0.2.2:8000` instead of `127.0.0.1` to reach an API running on the host machine.

For a production or HTTPS deployment, provide the public API URL:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.example.com
```

Release builds require an HTTPS API URL to protect authentication traffic.

### Run the complete HTTPS deployment

Set `DOMAIN` in `.env` to a domain that points to the server, then run:

```bash
docker compose up -d --build
```

Caddy handles HTTPS certificates and forwards secure traffic to the internal FastAPI service. Ports `80` and `443` must be available on the server.

## Testing

Run the backend regression tests:

```bash
cd api
python -m pytest
```

Run the Flutter tests:

```bash
cd myhealthtrackr_application
flutter test
```

## Security Notes

- Never commit `.env` or real API keys to source control.
- Use a unique, randomly generated `JWT_SECRET` in every environment.
- Keep PostgreSQL private and expose only the API or HTTPS reverse proxy.
- Use HTTPS for release builds and deployed authentication traffic.

## Project Status

MyHealthTrackr is an academic final-year project and is under active development. Features, API contracts, and deployment configuration may continue to evolve.
