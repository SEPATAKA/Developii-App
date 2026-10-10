# Developify Mobile

One Flutter application for **Investor and Landowner**, with shared authentication and portal switching. Application version **1.0.0+6**, source handover revision **r1**. The accepted UI includes the compact Investor calculator banner at standard and enlarged system text settings. Screens and domain journeys are implemented; repositories simulate data and financial operations. Production API integration, service configuration and distribution signing remain the receiving team's responsibility.

## Quick start

Use **Flutter 3.44.4 stable / Dart 3.12.2**. Install the native prerequisites in the [setup guide](docs/SETUP_GUIDE.md). Extract the source ZIP, then run these commands inside `developify-mobile/`:

```sh
flutter --version
flutter pub get --enforce-lockfile
dart run build_runner build
flutter devices
flutter run --target lib/main.dart \
  --dart-define=MOCK_MODE=true \
  --dart-define=MOCK_SCENARIO=success \
  --dart-define=FIREBASE_ENABLED=false \
  --dart-define=TELEMETRY_ENABLED=false \
  --dart-define=ONESIGNAL_APP_ID=
```

Select the Android emulator or iOS simulator when prompted, or add `-d DEVICE_ID` using an ID returned by `flutter devices`. Both portals are available in the app switcher; switching does not require another login. An authenticated cold restart starts on Investor Home.

Mock-only sign-in: `landowner.qa@developify.co.za` / `Developify@123`. Recovery/verification code: `123456`. Seeded transaction PIN: `1234`. The mock accepts any valid email and nonempty password; these are convenient test inputs, not production credentials. A changed PIN lasts for the current user in the running process and resets on logout, user change or restart. Recovery does not create a real server password. Login restoration does not persist the simulated wallet, submissions or KYC data; see the [persistence matrix](docs/ARCHITECTURE.md#persistence-and-session-boundaries).

## Guides

- [Setup guide](docs/SETUP_GUIDE.md): toolchain, configuration, commands and signing.
- [Architecture](docs/ARCHITECTURE.md): ownership, repositories, navigation and persistence.
- [API integration guide](docs/API_INTEGRATION_GUIDE.md): concrete interfaces, backend contracts and verification.
- [Observability and notifications](docs/OBSERVABILITY_AND_NOTIFICATIONS.md): existing adapters and the recommended next phase.
- [Handover status](docs/HANDOVER_STATUS.md): delivered scope, verification and integration inputs.

The standalone developer PDF is a reading copy of this documentation. Markdown is the editable source of truth. The exported [.source-revision](.source-revision) records the exact commit; it is expanded by Git archive, not a runtime configuration value.

## Stack and structure

Flutter/Dart, MobX with committed generated source, GetIt constructor composition, go_router, Dio, ScreenUtil, flutter_svg and flutter_secure_storage. Firebase and OneSignal adapters are optional and unconfigured in this delivery. Dependency versions are retained in [pubspec.lock](pubspec.lock); CocoaPods dependencies are retained in [ios/Podfile.lock](ios/Podfile.lock).

```text
lib/main.dart          Normal application entry point
lib/app/               Bootstrap, DI, environment and router
lib/core/              Money, errors, network, storage, services, theme, controls
lib/features/          Authentication, Investor, Landowner, profile and notifications
assets/                Runtime SVGs, images and licensed TASA fonts
test/                  Unit, widget, journey and architecture regressions
integration_test/      Maintained native device journeys
test_driver/           Native integration driver
tool/                  Launcher and splash resource generators
android/ and ios/       Native applications and build configuration
docs/                  The five handover guides
```

## Common commands

```sh
dart run build_runner build
dart format --output=none --set-exit-if-changed \
  lib test integration_test test_driver tool
flutter analyze
flutter test --reporter expanded
```

MobX `.g.dart` files are tracked; never edit them manually. The pinned build_runner does not need the obsolete `--delete-conflicting-outputs` flag. There is no package upgrade required to run this handover.

For normal Android debug and iOS simulator builds, use the exact disabled-service commands in [Build and native tests](docs/SETUP_GUIDE.md#build-and-native-tests). Android release-mode builds currently use debug signing for local testing. No production APK, AAB or IPA is part of the source handover.

The app uses local runtime assets and one font family, TASA Orbiter Display. Its [OFL licence](assets/fonts/TASA-Orbiter-OFL.txt), SVG identifiers, native launcher assets and splash resources are preserved. Regenerate launcher resources only when intentionally updating branding with `flutter test tool/generate_launcher_icons.dart`; verify with `flutter test test/launcher_icons_test.dart`. See the setup guide for optional test diagnostics.
