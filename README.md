# Scam Message Detector

Flutter app that analyzes suspicious SMS, email snippets, or URLs using the Google Gemini API (`gemini-3.1-pro-preview`).

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.11.0).
2. Copy the environment template and add your API key:

   ```bash
   cp .env.example .env
   ```

   Set `GEMINI_API_KEY` in `.env` to your [Google AI Studio API key](https://aistudio.google.com/apikey).

3. Install dependencies and generate code:

   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:

   ```bash
   flutter run
   ```

## Architecture

Feature-first clean architecture with Riverpod, Freezed, and `go_router`:

- `lib/core/` — theme, routing, env (`envied`), Dio
- `lib/features/splash/` — animated splash screen
- `lib/features/scam_detector/` — data, domain, and presentation layers

## Author

Shakhzod — Norton AI-First Intern project
