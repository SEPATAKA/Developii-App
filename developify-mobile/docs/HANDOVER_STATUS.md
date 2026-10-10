# Handover status

[Documentation entry point](../README.md)

## Delivered scope and identity

Developify Mobile **1.0.0+6**, handover revision **r1**, prepared 22 September 2026 for Ngoako Masetla. One app contains the accepted Investor and Landowner UI, shared authentication and portal switching. The accepted compact calculator-banner correction is included from baseline `0f417ec2fa7ff3fa4cf801f190d757a2052c345e` on `main`. The application version was not changed for documentation.

The source ZIP is exported from the final cleanup commit. Its exact revision is recorded in [.source-revision](../.source-revision); Git archive expands that file's revision marker. The accompanying checksum file identifies the same source commit and final ZIP/PDF hashes. The source package contains no repository history.

Runtime assets, SVG identifiers, image crops, TASA font licence, native launcher/splash resources, repository architecture and generated MobX source are preserved. No runtime asset or dependency/lockfile was changed. All maintained test assertions remain. Internal review material and editor state were removed from the working project. Optional maintained-test screenshot support now writes ignored build output and no longer exports internal geometry/asset inventories.

## Current service and feature state

| Area | Delivered state |
| --- | --- |
| Investor/Landowner screens, validation, routing, privacy, accessibility | Implemented UI/domain behavior; accepted presentation retained |
| Authentication/recovery/social sign-in | Simulated; mock login can restore securely for its unexpired demo session |
| Wallet, investment, deposits, withdrawals, earnings and receipts | Simulated data/operations; no production money movement |
| KYC, invitations, signatures and document previews | Simulated; no live identity, signature or document service |
| Repository interfaces, Dio/token storage | Existing integration skeleton; live repositories and token refresh still need implementation |
| Firebase analytics/crash/performance/config | Existing optional adapters; configuration required; collection disabled |
| OneSignal | Existing optional adapter; App ID empty; platform/provider integration required |
| Installation registry, analytics event dictionary, CI tester distribution | Recommended future implementation |
| Android signing | Existing debug signing, including release-mode local QA; no production signing delivery |
| iOS signing | Simulator verification only; production team/provisioning remains CTO-owned |

Verification uses `MOCK_MODE=true`, `MOCK_SCENARIO=success`, `FIREBASE_ENABLED=false`, `TELEMETRY_ENABLED=false`, and explicit empty `ONESIGNAL_APP_ID`. No production API, push or collection is activated. Setting `MOCK_MODE=false` or adding an API URL is not sufficient to connect services: registered mock requests become unavailable.

## Verification record

The accepted baseline was freshly regenerated, format-checked and analyzed with Flutter 3.44.4 / Dart 3.12.2; all 754 maintained tests passed. The final cleaned-source verification and native results are recorded below before source export. The accompanying checksum file records the fresh-extraction results for the exact finished archive, separately from the baseline. Follow the commands in [Setup](SETUP_GUIDE.md) to reproduce them.

| Check | Fresh result |
| --- | --- |
| Locked Pub dependencies | Passed `flutter pub get --enforce-lockfile`; app, Pub and Pod lockfiles unchanged |
| Generation / formatting / analyzer | Passed; generation wrote zero outputs; no analyzer issues |
| Full maintained host suite | 754 tests passed after cleanup |
| Runtime and assertion audit | 279 Dart files have identical non-comment tokens to baseline; all 2,380 assertion calls unchanged |
| Focused banner checks | All 12 width/text-scale cases passed; two saved before/after banner PNGs are byte-identical |
| Normal mock Android build | Debug APK built successfully with optional services explicitly disabled |
| Native Android review journey | Both tests passed: money/privacy/project guards/documents and portal switching |
| Native Android Landowner journey | Both tests passed, including login/recovery, draft resume/submission and switching |
| iOS simulator | Build blocked under Xcode 27: universal framework architecture check failed (exit 255); selected-simulator attempt reported dependency deployment targets below iOS 15. No fresh iOS journey success claimed |
| Source/package checks | Relative documentation links checked; private-path/credential/residue audit and `git diff --check` passed before export |

The Android build reports a future Kotlin Gradle Plugin compatibility warning for Firebase plugins. The pinned toolchain builds successfully; no upgrade or native migration was performed. The Xcode limitation and reproduction command are in the setup guide. Source builds are temporary validation artifacts and are excluded from delivery.

These checks verify the delivered mock application and source reproducibility within the recorded toolchain. They do not prove production API authorization, financial settlement, live KYC or store readiness. Historical delivery results are not used as fresh native verification.

## First integration steps and access inputs

1. Confirm environment/API contracts, identity provider, user/entity authorization and session expiry/revocation cleanup.
2. Connect authentication/profile and one read-only catalogue journey, retaining repository interfaces and independent stores.
3. Reconcile wallet/account/portfolio reads before enabling financial writes; agree quotes, idempotency, fees, capacity and final server authorization.
4. Supply durable draft/document/KYC contracts for all four entity types and Landowner submissions.
5. Confirm Firebase/OneSignal projects, privacy/consent policy, installation registry, notification payloads and monitoring owners.
6. Supply signing/store/CI access and prove staging failure paths before production release.

The [API guide](API_INTEGRATION_GUIDE.md) lists exact interfaces, methods, tests and backend inputs. The [service guide](OBSERVABILITY_AND_NOTIFICATIONS.md) provides recommendations and current official links. These production inputs do not block delivery of the accepted runnable mock source.

Delivery consists of a source ZIP with Markdown documentation, a standalone developer PDF and a checksum file. File sharing follows the owner's instruction: **Anyone with the link, Viewer/download access** for the new files; the existing parent folder permissions and previous deliveries remain unchanged. No automatic email or group message is sent. No source push, live service activation or store deployment is part of this handover.
