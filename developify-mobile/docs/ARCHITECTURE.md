# Architecture

[Documentation entry point](../README.md)

## Ownership and request flow

```text
main -> bootstrap -> AppDependencies (one private GetIt container)
                  -> SessionService -> router authentication guards
                  -> optional telemetry / push / ApiClient
                  -> repository singletons and independent store factories

route/widget owns controllers and its store
    -> store validates UI input and manages observable load state
    -> repository interface returns Result<domain model>
    -> mock data today; authenticated API adapter in the next phase
    -> immutable models / change stream
    -> store ignores stale results and updates the view
```

[bootstrap](../lib/app/bootstrap.dart) restores the mock session before composition and installs framework/platform error handlers only when launching. [AppDependencies.create](../lib/app/di/app_dependencies.dart) owns registrations and disposal. It uses `GetIt.asNewInstance`, singleton repositories/services and factories for route-owned stores. Widgets own/dispose text, scroll, animation and focus controllers. Stores own/dispose subscriptions, reactions, timers and request generations. `AppDependencies.dispose` resets the container; `DevelopifyApp` owns its router unless one was injected.

Stores never import, inject, observe or call another store. They receive repository/service interfaces through constructors. Shared repositories and immutable results coordinate features. The [architecture tests](../test/architecture_test.dart) enforce store independence, primitive routing, local assets, centralized colours and typography.

## Feature map

| Source folder | Responsibility |
| --- | --- |
| [app](../lib/app/) | Environment, initialization, constructor composition, named routes and shells |
| [core](../lib/core/) | `Result`, cancellation/lifecycle, `MonetaryAmount`, HTTP, storage, telemetry/push, shared theme and controls |
| [authentication](../lib/features/authentication/) | Shared sign-in/recovery and portal registration models/stores |
| [investor](../lib/features/investor/) | Catalogue, project content, accounts, transfers, holdings, independent feature stores and four KYC flows |
| [landowner](../lib/features/landowner/) | Property states, submission drafts, earnings, independent Home/properties/submission stores |
| [notifications](../lib/features/notifications/) | Landowner notification list and local chat |
| [profile](../lib/features/profile/) | Shared profile, preferences, payout account and simulated security controls |
| [shared](../lib/features/shared/) | `AppUser`, `EntityType`, `Experience` and experience selection |
| [onboarding](../lib/features/onboarding/) | Shared onboarding state and presentation |

Investor KYC subfolders contain its plan, typed field/member/document models and validation. Core money and errors are reused; domain behavior is not placed inside a global application store. [API integration](API_INTEGRATION_GUIDE.md) maps every repository and method group.

## Routing and shared identity

There is one `MaterialApp.router`, initialized with a 393 x 852 ScreenUtil design reference. [createAppRouter](../lib/app/router/app_router.dart) owns public/protected redirects, pending protected locations, the Landowner shell and Investor routes. [investor_routes.dart](../lib/app/router/investor_routes.dart) composes the Investor tab shell and feature routes. Stable route names live in [route_names.dart](../lib/app/router/route_names.dart). Routes pass primitive IDs and scalar query values; domain objects are resolved through repositories rather than passed in nonserializable `extra`.

`SessionService` is a non-MobX shared authentication service. `Experience` selects Investor or Landowner within that login. `InvestorAccountContext` adds entity scope (`individual`, `company`, `trust`, `stokvel`) and a revision that invalidates results when scope changes. An entity selection updates the saved user's entity; entity-specific working data remains in memory. The server must independently authorize membership, roles and resources for every request. Client selection is not authorization.

The router remembers a protected location encountered before login and clears it for explicit logout. This supports existing in-process redirects, but is not a complete cold-start notification queue. Push initialization/readiness and server resource authorization still need integration.

## Errors, cancellation and financial ownership

[Result](../lib/core/errors/result.dart) is `Success<T>` or `Failure<T>(AppFailure)`. Failures carry a typed kind, user-facing message, optional HTTP code and field errors. Views use `LoadStatus.initial/loading/success/empty/error`; cancellation should not be presented as a failed user action.

[Lifecycle](../lib/core/utils/lifecycle.dart) advances a generation on every new request and on disposal. A completed old request cannot overwrite newer state. [Cancellation](../lib/core/utils/cancellation.dart) and [MockRequestScope](../lib/core/services/mock_request_scope.dart) cancel outstanding operations; Investor repositories additionally check `InvestorAccountContext.isCurrent`. Keep these ownership rules when adding Dio `CancelToken` handling. See the concurrent favourite/detail, account-scope and logout regressions before modifying repository streams.

`MonetaryAmount.minorUnits` stores exact cents with an explicit currency. Multiplication/rounding uses integer/BigInt operations. Current investment policy is ZAR, minimum R1 and a 36-month monthly simple-interest preview. `InvestmentProjection` also represents historical cadences; its constructor default is quarterly, so a new adapter must explicitly pass the actual schedule. Round total earnings once and allocate residual cents across payments. For R100 at 14.5% over 36 months, total earnings are R43.50: thirty R1.21 and six R1.20 payments. Principal returned at maturity is not another credit of aggregate proceeds.

[InvestorAccountSummary.from](../lib/features/investor/domain/account_summary.dart) computes Home overall balance from available ZAR wallet funds plus distinct holdings that still hold principal. It excludes projected earnings and avoids counting a transfer or duplicate holding twice. Historical schedules and settled amounts come from recorded models; a projection is not a ledger entry.

`InvestmentStore` preserves project ID, entered amount, agreement and quote through funding/review; repeated authorization is guarded. The mock account repository rechecks PIN, KYC, current project terms, capacity and balance and supports operation replay signatures. These are domain regressions to preserve, not production security guarantees. A live backend must implement atomic capacity reservation, transaction authorization and idempotent financial writes.

## Persistence and session boundaries

| State / owner | Portal or entity switching | Process restart | Explicit logout / expiry |
| --- | --- | --- | --- |
| Mock login, onboarding, returning user / `SessionService` + `SecureSessionStorage` | One login; selected experience does not replace identity | Secure JSON restores unexpired user, onboarding and selected user entity; experience starts Investor | Sign-out clears active user/expiry, retains onboarding and returning-user record; default session duration is 24 hours |
| Access token / `TokenStorage` | Shared abstraction | Mock uses `MemoryTokenStorage`; live mode selects secure token storage, but auth/refresh adapters are absent | `AppDependencies.logout` calls `clearToken`; expiry alone calls session sign-out, not the full async logout coordinator |
| Investor entity / `InvestorAccountContext` | Per-entity data retained; revision invalidates old requests | Selected user entity restored; per-entity residency history is rebuilt | User change resets scope and residency cache |
| Wallet, transactions, holdings, payment methods / mock account repository | Per entity; preserved within running user session | Fixtures re-created; simulated financial changes are not durable | User change/sign-out clears account maps via context |
| Investor investment/transfer drafts / `InvestorDrafts` | Keyed by entity + project or transfer kind | Lost | Cleared on user change/sign-out; completed flow can clear its own draft |
| Favourites and searches / mock catalogue | Per entity, preserved across portal switches | Defaults/fixtures restored | Cleared on user change/sign-out; catalogue fixture contributions are process-local, not a durable backend ledger |
| Investor KYC / mock KYC repository | Entity drafts remain in current process | Fixtures/default state re-created | User change/sign-out invalidates requests and clears scoped draft data |
| Investor privacy / mock account repository | Shared across Investor views for current entity | Defaults restored | Reset with the account map |
| Landowner properties, submissions, drafts and privacy / mock Landowner repository | Shared within process; portal switch preserves them | Fixtures restored; saved local drafts/submissions lost | Explicit `AppDependencies.logout` calls `clearSession`. Expiry alone does not call this repository's cleanup |
| Profile preferences, security toggles, payout account / mock profile repository | Shared within process | Defaults restored; user profile fields in session JSON can survive | Explicit logout resets repository state. Expiry alone does not invoke its cleanup |
| Landowner notifications/chat / mock notification repository | Shared within process | Seeded content restored | Explicit logout clears local changes; expiry alone does not invoke repository cleanup |
| PIN / `MockTransactionAuthorization` | Current authenticated user; portal/entity switching does not reset it | Seed `1234` restored | Resets to `1234` on user change/sign-out; no real biometric enrollment |

Expiry monitoring starts in `DevelopifyApp`. Its timer signs out the session; Investor context listeners clear scoped state. Full logout additionally clears Landowner/auth/profile/notification repositories, token storage and push identity. Production integration must unify expiry/revocation with the agreed cleanup coordinator, including pending writes, push unbinding and telemetry identity cleanup. This is documented integration work; the accepted behavior was preserved.

## Presentation invariants

The accepted calculator promotion keeps a 370:92 composition scaled once from available width. Only its two live `Text` widgets use `TextScaler.noScaling`; other app text retains system accessibility scaling. Its SVG crop, rounded clipping, reachable tap target and screen-reader text remain. The inactive portfolio promotion is retained as an intentional alternate state.

Privacy uses literal `****` and hidden-value semantics; masking must remove amounts from accessible labels as well as paint. Keep the [client policy](../test/client_review_policy_test.dart), [privacy/security state](../test/security_state_test.dart), [responsive](../test/investor_responsive_test.dart) and [banner layout](../test/calculator_promotion_layout_test.dart) checks when integrating data.

Runtime SVGs, raster crops, meshes, native icons, splash and licensed fonts are retained. Optional screenshot output is diagnostic only. Maintained tests load normal source/native assets, without depending on private review files.
