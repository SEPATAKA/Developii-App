# Observability and notifications

[Documentation entry point](../README.md)

This is a recommended next phase, not an enabled collection or delivery pipeline. No cloud resources, permissions, identifiers or new packages were activated for handover. Official documentation was consulted on 22 September 2026; the API names below were also checked against the delivered packages, rather than assumed from newer examples.

## Existing service adapters

[telemetry.dart](../lib/core/services/telemetry.dart) defines `AnalyticsService`, `CrashReporter`, `FeatureConfigService` and `PerformanceService`, with Firebase and no-op implementations. Locked versions: firebase_core 4.14.0, firebase_analytics 12.5.0, firebase_crashlytics 5.3.0, firebase_performance 0.11.5 and firebase_remote_config 6.6.0. [push_notification_service.dart](../lib/core/services/push_notification_service.dart) wraps onesignal_flutter 5.6.8.

Firebase is disabled by default. `TelemetryServices.initialize` accepts optional `FirebaseOptions`, initializes once, configures collection gates and returns no-ops if setup fails. The composition root currently supplies no platform options. Add approved environment configuration through the existing initialization path; avoid another independent initializer. The analytics wrapper supports `screen(name)` but no app screen-event call sites are wired. Performance supports `trace(name, operation)` but workflows are not instrumented. Crash hooks are connected to the disabled reporter. Remote Config has a typed default and fetch adapter; it is not a business authorization service. [Official Flutter setup](https://firebase.google.com/docs/flutter/setup) explains platform registration/options and native product configuration.

OneSignal initializes only with a nonempty app ID, registers click/foreground listeners, exposes permission/login/logout/tag methods, and removes listeners on disposal. No app ID, device-registry API or native production transport setup is delivered. It can initialize independently of Firebase/mock flags: leave `ONESIGNAL_APP_ID` explicitly empty during demo verification.

## Analytics proposal

Extend `AnalyticsService` with a small typed event interface using the pinned SDK's `logEvent`; retain `logScreenView` for screen names. Track the effective visible named route centrally around go_router, including changes between nested portal tabs. Deduplicate consecutive identical screen names and avoid counting both a shell and its child as separate screen impressions. Use stable labels such as `investor_project`, never full paths or IDs. The screen observer/event layer is future work, not implemented tracking. See [Analytics setup](https://firebase.google.com/docs/analytics/flutter/get-started) and [screen-view guidance](https://firebase.google.com/docs/analytics/screenviews).

Proposed event dictionary (product owner approves definitions; mobile team emits once at the stated trigger):

| Event | Trigger | Allowed parameters |
| --- | --- | --- |
| `onboarding_step` | A user reaches a new onboarding step | `portal`, bounded `step` |
| `sign_in_outcome` | An attempt completes | `method`, `outcome` enum; no credential/error text |
| `portal_switch` | User completes an app-switcher selection | `from_portal`, `to_portal` |
| `project_view` | A project screen resolves successfully | `category` enum; no project/account IDs |
| `calculator_use` | User completes a valid preview | `entry_point`; no principal, rate or result values |
| `submission_progress` | A persisted step is acknowledged | `workflow`, bounded `step`, `outcome` |
| `notification_open` | One validated tap is accepted for handling | `destination` enum, `app_state` enum |

Do not log balances, exact investments, email/phone, PIN/OTP, tokens, bank/card data, tax information, KYC answers or document contents. Avoid free text and high-cardinality IDs. Treat analytics as usage measurement, not the financial ledger or compliance audit log; backend operational auditing needs a separate controlled design.

The existing build gate is not a consent screen. Implement approved consent and runtime collection controls using the pinned `setConsent` and `setAnalyticsCollectionEnabled` APIs, including native defaults where necessary. Use distinct debug/staging data and verify events in [DebugView](https://firebase.google.com/docs/analytics/debugview), disabling debug mode after checking. On logout/account change, clear analytics identity (`setUserId(id: null)`) and any user properties added by the implementation. The current logout path does not do this because analytics identity is not currently set. Product/privacy owners approve collection; mobile and analytics owners verify event counts and exclusions before rollout.

## Crashlytics proposal

[bootstrap](../lib/app/bootstrap.dart) already installs `FlutterError.onError` and `PlatformDispatcher.instance.onError`. Extend that single path rather than adding duplicate global reporters. It reports framework/platform errors as fatal today. `FirebaseCrashReporter.record` sends error runtime type and the original stack, avoiding raw exception values. Improve redaction while preserving enough sanitized context to diagnose unexpected failures; do not record routine validation/cancellation as crashes. Background isolates, native crashes and handled exceptions need appropriate coverage and verification, not an assumption that every error is automatically captured. See [Crashlytics Flutter setup](https://firebase.google.com/docs/crashlytics/flutter/get-started) and [custom reporting](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports).

Use safe breadcrumbs and low-cardinality release/version/build/environment tags. Exclude user-entered text, paths with identifiers, payloads and credentials. Report handled unexpected failures deliberately with stacks and nonfatal classification. Review the existing all-fatal global handling as part of integration, without duplicating a report in the repository and global hook.

Complete Android product plugin/mapping integration and iOS Crashlytics symbol upload after approved Firebase registration. Current Android release builds use the existing debug signing and no Dart obfuscation flags. If future builds use `--obfuscate --split-debug-info`, retain exact Dart symbols together with release metadata; preserve native mapping files/dSYMs matching each release. Confirm symbolication on both platforms. [Flutter obfuscation guidance](https://docs.flutter.dev/deployment/obfuscate) explains the Dart symbol requirement.

In a staging-only build, trigger one controlled test exception, relaunch if required, and verify a single correctly symbolicated report with sanitized context and the right build/environment. Remove the trigger from normal distributed builds. Assign an on-call owner, alert routing, regression threshold and release-triage responsibility before enabling collection.

## Performance proposal

`FirebasePerformanceService.trace` already stops its trace in `finally`, including failed operations. Add bounded traces for startup and important catalogue/account/submission loads. Measure the actual [Dio transport](../lib/core/network/api_client.dart): the pinned SDK supports `FirebasePerformance.newHttpMetric`. Instrument one transport boundary if requests are not already measured; do not add overlapping interceptor and repository metrics for the same request. Close each metric on success, error and cancellation, with response code and safe payload sizes where available. Redact dynamic URL paths/query values and use approved endpoint templates. [Performance setup](https://firebase.google.com/docs/perf-mon/flutter/get-started) and [custom network monitoring](https://firebase.google.com/docs/perf-mon/flutter/get-started) cover native setup and manual metrics.

Keep names/attributes bounded (`environment`, route category, outcome); never attach balances, user/entity IDs, document names or tokens. Separate initial startup from background work and use staging samples to validate counts before rollout.

Firebase Performance does not automatically measure each Flutter screen as a distinct native rendering screen. Use profile-mode Flutter DevTools frame analysis on representative physical devices for rendering/jank, with the accepted banner and large-text layouts included. Simulator/debug timings are not production performance evidence. [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance) describes this workflow.

## Proposed installation registry

No backend installation registry is implemented. Add an authenticated API after agreeing schema and lifecycle:

- An **installation ID** is an app-scoped opaque random identifier for an installation, not IMEI, advertising ID, fingerprint or proof of physical-device identity. Persistence across reinstall varies by platform/storage and must not be assumed.
- A **backend device-record ID** identifies the registry row. A **session ID** identifies one authenticated session. **User/entity IDs** identify authorized ownership/scope. A **push subscription ID/token** identifies a provider transport and can rotate independently.
- Upsert platform, app version/build, bounded supported metadata, permission state, provider/subscription identity and timestamps. Permit registration before permission or token availability. Derive ownership from authentication, not an arbitrary client-supplied user ID.
- Handle subscription rotation, multiple devices, account changes, logout unbinding, revocation and stale-record removal. Retain only agreed metadata and make retries idempotent. The server validates updates to records already bound to another account.

`OneSignal.User.pushSubscription.addObserver` exists in 5.6.8 and can drive subscription updates; the current abstraction does not expose it. Extend the abstraction and dispose observers correctly. Do not label the mock profile's previous-device list as this registry.

## Push delivery and navigation

Prefer completing the existing OneSignal adapter unless the CTO explicitly selects direct FCM. OneSignal still needs Android FCM and iOS APNs configuration, approved App ID, platform registration, capabilities and any required notification service extension/app-group setup. No native service extension or production APNs entitlement is delivered. Follow [OneSignal Flutter setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup) and the [mobile SDK reference](https://documentation.onesignal.com/docs/en/mobile-sdk-reference).

Ask for notification permission at a contextual user action, with consent and useful denial/settings behavior. The existing wrapper calls `requestPermission(false)` and safely returns false when unconfigured. Bind identity after restored/new login and update/unbind on account/logout transitions. `DevelopifyApp` currently listens for later session changes but does not explicitly synchronize the already-restored identity on first attachment; address that when completing push. The pinned SDK provides `OneSignal.loginWithJWT(externalId, jwt)` for a backend-issued identity-verification token; the current wrapper uses `login`. Agree provider-side identity verification and server issuance before exposing verified login through the abstraction. Signing secrets remain backend-only.

Current temporary typed payloads are `destination: notifications` or `destination: property` with an ID matching 1-80 letters/digits/underscore/hyphen. `PushTarget.fromPlaceholder` rejects other shapes. Current tap handling navigates directly to Landowner routes; router guards can defer a protected location during login. This is not a durable cold-start queue, entity authorization check, arbitrary deep-link parser or Investor notification route contract. Foreground targets are exposed as a stream but no app subscriber/presentation policy is wired.

Proposed completion: agree versioned typed payloads and stable event IDs; deduplicate repeated taps/deliveries; handle foreground/background/terminated startup; defer until router, session and authorized entity scope are ready. Resolve only primitive project/document IDs after authenticated resource checks. Reject stale/inaccessible targets, handle permission denial and sync unread counts/preferences from the backend. Keep notification bodies non-sensitive. Refresh authoritative state after a tap; never trust pushed amounts or settlement status.

An FCM-only choice requires replacing OneSignal identity/subscription/listener handling, adding and configuring firebase_messaging, platform/background handlers and a single presentation/navigation pipeline. Do not run competing OneSignal and FCM presentation pipelines by default. See [FCM Flutter setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).

OneSignal REST keys, APNs signing keys, service-account credentials and server secrets never belong in Flutter source or the source ZIP.

## Remote Config and tester distribution

`FirebaseFeatureConfig` seeds `review_business_days=10`, validates fetched values to 1-30, uses a 10-second fetch timeout and 12-hour minimum interval, and falls back safely. Proposed use: non-sensitive feature availability, maintenance/version messages and rollout controls with typed defaults. It must not grant authorization, override server financial/KYC limits or contain secrets. The adapter's `refresh()` calls `fetchAndActivate`; no release policy or UI fetch lifecycle is wired. [Remote Config Flutter guide](https://firebase.google.com/docs/remote-config/flutter/get-started) provides setup details.

Firebase App Distribution is a future tester/CI workflow, not a runtime SDK requirement. Prepare approved app registrations, signing, tester groups, least-privilege CI credentials, checksums/release notes, matching symbols and staging gates; then verify delivery and tester install before calling a pipeline operational. Production signing and store accounts remain CTO-owned. See [App Distribution](https://firebase.google.com/docs/app-distribution).

Recommend separate development, staging and production Firebase projects, while retaining both portals in the same app. The CTO must approve environment strategy, retention, consent and collection policy before activation. [Firebase environment best practices](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices) supports this separation.
