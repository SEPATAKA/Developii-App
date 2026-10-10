# Setup guide

[Documentation entry point](../README.md)

## Tested toolchain

| Component | Source expectation and tested installation |
| --- | --- |
| Flutter | 3.44.4 stable, framework revision `ad70ec4617` |
| Dart | 3.12.2, supplied by Flutter |
| Repository constraints | `sdk: ^3.12.2`, `flutter: >=3.44.4`; minimum constraints, not an exact SDK manager pin |
| Java | Microsoft OpenJDK 17.0.17; Java/Kotlin JVM target 17 |
| Android | compile/target SDK 36, minimum SDK 24; NDK 28.2.13676358 from this Flutter SDK |
| Gradle / AGP | Wrapper 9.1.0 / Android Gradle Plugin 9.0.1 |
| Kotlin | 2.3.20 declared in settings; existing Flutter compatibility flags retained |
| Apple tooling | Xcode 27.0 (27A266a), CocoaPods 1.16.2 |
| iOS | Deployment target 15.0; CocoaPods integration; Swift Package Manager disabled in pubspec |

Use this tested Flutter version first. Do not automatically upgrade Flutter, Gradle, Kotlin or pods during integration. The host also has newer Android SDK platforms; the app resolves API 36 from Flutter. `flutter doctor` reports Android licence status as unknown on the verification host; actual build outcomes are recorded in [handover status](HANDOVER_STATUS.md). On a new workstation, use `flutter doctor -v` and review/accept applicable SDK licences as the responsible developer.

Native identifiers were checked independently: Android `za.co.developify.developify_mobile` in [app/build.gradle.kts](../android/app/build.gradle.kts), and iOS `za.co.developify.developifyMobile` in [project.pbxproj](../ios/Runner.xcodeproj/project.pbxproj). They are provisional distribution identifiers; confirm them before registering production apps. The two portals remain one app per environment.

## Clean extraction and dependencies

Extract the ZIP into an ordinary writable directory. Enter its single `developify-mobile/` root; no files from another checkout are required. Preserve dotfiles and executable permissions. Retained Gradle wrapper scripts/JAR and native projects are included; Flutter regenerates machine-specific files locally.

```sh
flutter --version
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed \
  lib test integration_test test_driver tool
flutter analyze
flutter test --reporter expanded
```

`--enforce-lockfile` is supported by the tested Flutter/Pub toolchain. It must fail if locked resolution cannot be honoured; do not delete or regenerate the lockfile to hide a mismatch. Pub and native dependency downloads require network access on a machine without caches. Run commands from the extracted root so asset and test paths resolve correctly.

For iOS on macOS, run `flutter pub get --enforce-lockfile` before `(cd ios && pod install --deployment)`. The deployment flag enforces [Podfile.lock](../ios/Podfile.lock). Open `ios/Runner.xcworkspace`, not the `.xcodeproj`, for native development. Select a locally installed compatible simulator using `flutter devices` or Xcode. A physical iPhone additionally requires an approved signing team and provisioning.

## Configuration

[AppEnvironment.fromDefines](../lib/app/environment/app_environment.dart) reads compile-time `--dart-define` values. There is no `.env` loader. Values are embedded in the application and must never contain server/admin secrets.

| Key | Parser, default and meaning | Safe example |
| --- | --- | --- |
| `MOCK_MODE` | `bool.fromEnvironment`, defaults true. False makes registered mock operations unavailable; does not install live repositories. | `true` |
| `MOCK_SCENARIO` | String mapped to the cases below; unknown values fall back to success. | `success` |
| `MOCK_DELAY_MS` | `int.fromEnvironment`, defaults 350 milliseconds; malformed values use the default. Use a nonnegative value; the parser itself does not clamp negatives. | `350` |
| `API_BASE_URL` | String, defaults empty. `apiUri` accepts only HTTPS with host and no user-info, query or fragment. Only needed once API adapters are implemented. | `https://api.example.com` (illustration only) |
| `FIREBASE_ENABLED` | `bool.fromEnvironment`, defaults false. Attempts optional Firebase initialization when true; configuration failure falls back to no-ops. | `false` |
| `TELEMETRY_ENABLED` | `bool.fromEnvironment`, defaults false. Gates analytics/crash/performance collection after Firebase initialization. | `false` |
| `ONESIGNAL_APP_ID` | String, defaults empty. Empty/whitespace disables initialization; a nonempty value attempts initialization independently of mock/Firebase flags. | Explicit empty value |

Supported scenario strings: `success`, `empty`, `network_failure`, `low_balance`, `incomplete_kyc`, `pending_verification`, `rejected_verification`, `no_projects`, `no_transactions`, `no_notifications`, `no_portfolio`, `withdrawal_unavailable`, `payment_method_unavailable`, `validation_failure`, `missing_item`. Applicability varies by repository. `network_failure` fails the first request on each affected repository behavior and then permits retry.

For bool defines, use literal `true` or `false`. Keep the explicit empty OneSignal define in verification commands, and avoid personal IDE launch profiles or `--dart-define-from-file` inputs. No approved Firebase client options, Google services files or OneSignal App ID are supplied. An API URL by itself does not connect auth or any repository.

## Build and native tests

Normal mock launch:

```sh
flutter run --target lib/main.dart \
  --dart-define=MOCK_MODE=true \
  --dart-define=MOCK_SCENARIO=success \
  --dart-define=FIREBASE_ENABLED=false \
  --dart-define=TELEMETRY_ENABLED=false \
  --dart-define=ONESIGNAL_APP_ID=
```

Normal Android build (temporary validation output):

```sh
flutter build apk --debug --no-pub --target lib/main.dart \
  --dart-define=MOCK_MODE=true \
  --dart-define=MOCK_SCENARIO=success \
  --dart-define=FIREBASE_ENABLED=false \
  --dart-define=TELEMETRY_ENABLED=false \
  --dart-define=ONESIGNAL_APP_ID=
```

iOS simulator build command, without distribution signing (currently blocked on the verification host; see the Xcode 27 limitation below):

```sh
flutter build ios --simulator --debug --no-pub \
  --target lib/main.dart \
  --dart-define=MOCK_MODE=true \
  --dart-define=MOCK_SCENARIO=success \
  --dart-define=FIREBASE_ENABLED=false \
  --dart-define=TELEMETRY_ENABLED=false \
  --dart-define=ONESIGNAL_APP_ID=
```

Native journeys use independent test composition and deterministic fixture data:

```sh
flutter drive --no-pub \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/client_review_test.dart -d DEVICE_ID
flutter drive --no-pub \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/landowner_flow_test.dart -d DEVICE_ID
```

Replace `DEVICE_ID` with the actual ID. The first journey covers Investor money/privacy/project flows and portal switching; the second covers Landowner drafts and submission. Also retain `calculator_banner_test.dart`, `investor_flow_test.dart`, `investor_auth_flow_test.dart`, `investor_verification_test.dart`, `investor_amount_test.dart` and `investor_keyboard_test.dart` for focused native checks. Read their setup before running, since they deliberately create test sessions rather than verify a normal production login.

Optional diagnostics are build/test tooling, not application configuration: `CAPTURE_FIDELITY=true` enables screenshot captures for widget regressions; `FIDELITY_OUTPUT` overrides their default `build/test-artifacts/screenshots` location. `CAPTURE_SCREENSHOTS=true` enables basic app-test captures. `CAPTURE_NATIVE_SCREENSHOTS=true` enables optional native captures where supported. The integration driver writes `build/integration-results`, overridable with the shell variable `DEVELOPIFY_TEST_OUTPUT`. `LAUNCHER_PREVIEW_DIR` optionally writes icon previews when running the launcher generator. Generated diagnostics are not required input fixtures.

## Troubleshooting

- Generation: rerun `dart run build_runner build`; never hand-edit `.g.dart`. A stale generated file is a source consistency problem, not a reason to disable analysis.
- Assets: run from the root after Pub resolution. Check [AppAssets](../lib/core/assets/app_assets.dart), [pubspec](../pubspec.yaml) and exact filename case. Do not substitute missing runtime art with removed design references.
- Android: verify Java 17, installed SDK 36/NDK, network and wrapper permissions. `android/local.properties` is created for the current machine. Existing AGP compatibility flags in [gradle.properties](../android/gradle.properties) are intentional; this handover does not migrate the build system.
- iOS: resolve Pub first, then `pod install --deployment`. A lock mismatch needs investigation, not `pod update`. Ensure the selected simulator runtime is installed. Keep the workspace's deployment target at least 15.0 for the pinned Firebase dependencies.
- Optional services: disabled services are expected. With Firebase enabled, initialization errors yield no-ops. Provide approved platform options and native setup before expecting dashboards. Consult [the service guide](OBSERVABILITY_AND_NOTIFICATIONS.md).
- Native signing: simulator success does not prove device or store signing. Android `release` currently uses the local debug identity; a new developer's debug identity can differ. Do not distribute that build as production or overwrite installed apps with incompatible signing.

## Current Xcode 27 limitation

The normal universal simulator build failed in Flutter framework architecture verification (`debug_unpack_ios`, Xcode exit 255). A selected iPhone 17 / iOS 26.5 simulator attempt also failed under Xcode 27 with generated dependency targets below the supported iOS 15.0 minimum. No successful fresh iOS build or native journey is claimed for this handover host. The app target itself remains iOS 15.0. Do not silently migrate the native project or upgrade dependencies to hide this result; the receiving team should verify with an agreed compatible Xcode/toolchain before iOS distribution. Android builds and host tests are independently verified.

## Production distribution and environments

The CTO owns package/bundle confirmation, signing certificates/keystores, store accounts, privacy declarations, service registrations and CI access. No private signing material is included. Plan approved development, staging and production configuration with independent service projects and clear release labels. Keep credentials in controlled CI secret storage, not `--dart-define` or source files. See [the recommended environment workflow](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices).

Release-mode QA is useful for performance validation with mock data; it is separate from production signing, server integration and store deployment. Source delivery requires none of those external activations.
