# myhealthtrackr_application

My Final Year Project application

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Real Login Setup

The Flutter app should not connect directly to `myhealthtracker_db`. Use this flow instead:

`Flutter app -> backend API -> myhealthtracker_db`

This project now sends login requests to:

`POST {API_BASE_URL}/auth/login`

Expected JSON request body:

```json
{
  "email": "user@example.com",
  "password": "plain-text password from the form"
}
```

Example success response:

```json
{
  "token": "jwt-or-session-token",
  "userId": "123"
}
```

Example failure response:

```json
{
  "message": "Invalid email or password"
}
```

Run the app with your backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Notes:

- Use `10.0.2.2` if you are running the API on your machine and testing on an Android emulator.
- On iOS simulator, `http://127.0.0.1:3000` usually works for a local API.
- Your backend must store hashed passwords, compare them securely, and return `401` for invalid credentials.
