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

4. **Android only:** `flutter_llama` on pub.dev does not ship `llama.cpp` and its default Vulkan Android build fails when cross-compiling. Run once after `pub get` (clones sources and applies CPU-only patches):

   ```powershell
   # Windows
   .\tool\setup_flutter_llama.ps1
   ```

   ```bash
   # macOS / Linux
   chmod +x tool/setup_flutter_llama.sh
   ./tool/setup_flutter_llama.sh
   ```

   Re-run this script after upgrading `flutter_llama` or clearing the pub cache.

5. Run the app:

   ```bash
   flutter run
   ```

   If Android build fails with Kotlin cache errors (project on `E:` and pub cache on `C:`), `android/gradle.properties` already sets `kotlin.incremental=false`. If CMake errors persist, run `flutter clean`, re-run the setup script, then build again.

## Architecture

Feature-first clean architecture with Riverpod, Freezed, and `go_router`:

- `lib/core/` — theme, routing, env (`envied`), Dio
- `lib/features/splash/` — animated splash screen
- `lib/features/scam_detector/` — data, domain, and presentation layers

## Author

Shakhzod — Norton AI-First Intern project
