# OTTKing App

Professional Flutter boilerplate for a secure live TV streaming platform with mobile and smart TV experiences.

## Project Overview

This workspace contains a modular Flutter starter template that includes:

- Splash screen with 3-second redirect
- Home screen with banner slider and channel categories
- Player screen with remote zapping and secure media playback hooks
- Settings screen with theme toggle, account popup, subscription plans, and smart TV boot option
- Provider-based state management
- Secure API communication architecture using HMAC and encrypted payloads

## Architecture

- `lib/main.dart` – bootstrap and dependency injection
- `lib/app/app.dart` – routing and MaterialApp
- `lib/presentation/providers/app_state.dart` – shared app state
- `lib/data/services/*` – secure API, encryption, device detection, secure storage
- `lib/presentation/screens/*` – splash, home, player, settings
- `lib/presentation/widgets/*` – reusable remote-friendly widgets
- `docs/architecture.md` – detailed architecture guide
- `docs/security.md` – security model and hardening checklist

## Suggested Next Steps

1. Replace placeholder API and encryption secrets in `lib/core/constants/app_constants.dart`
2. Point `apiBaseUrl` to your backend endpoint
3. Implement actual server-side HMAC verification and encrypted payload parsing
4. Add real brand assets and final stream URLs
5. Run `flutter pub get` and `flutter run`

## Development Notes

- State management: Provider
- Remote navigation: `RawKeyboardListener` + `FocusableActionDetector`
- Media playback: `video_player`
- Secure local storage: `flutter_secure_storage`

If you want, I can next generate a production-ready `android` / `ios` configuration, add CI scripts, or expand the repository into a fully runnable Flutter project.