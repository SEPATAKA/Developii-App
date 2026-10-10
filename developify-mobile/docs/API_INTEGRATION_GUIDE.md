# API integration guide

[Documentation entry point](../README.md)

For Ngoako Masetla and the receiving engineering team. This is a map of the delivered interfaces and integration responsibilities, **not a working OpenAPI specification**. No production endpoints, provider sessions or deployment pipelines are implemented by this document.

## Integration status and composition

All repository registrations are in [AppDependencies.create](../lib/app/di/app_dependencies.dart). Mock classes under each feature's `data/` folder are registered against interfaces under `domain/`. They preserve loading, empty, validation, retry, cancellation and simulated domain behavior without infrastructure. `MOCK_MODE=false` sets `MockBehavior.available=false`; a configured URL does not substitute live repositories.

Replace implementations at this composition root while keeping independent stores, route ownership and typed models. Add agreed server contracts before financial or KYC writes. Some current interfaces deliberately expose synchronous local draft/simulation operations. They are not ready-made network endpoints: introduce explicit asynchronous persistence/quote contracts where required, with targeted tests, rather than hiding unawaited network writes behind synchronous setters.

## Inputs the CTO must supply

- Development/staging/production base URLs, TLS and environment ownership; agreed API schema/versioning and example responses.
- Identity provider and auth/recovery/social-login contract; token issuance, refresh rotation, expiry, revocation and logout rules. Firebase Authentication is not assumed.
- User/entity membership, roles, object authorization, account selection and session policy for both portals.
- Exact money/rate/fee, quote expiry, capacity, idempotency, ledger, settlement, reconciliation and error specifications.
- Pagination/sorting/filtering, resource IDs, status transitions, timestamps/time zones, server validation field keys and rate limits.
- KYC provider/environment, four entity workflows, document storage, upload limits, review/signature/retention rules and callback verification.
- Payment provider sandbox, tokenization/authorization flow, bank verification and authenticated webhook access.
- Push provider and installation-registry contracts, service project/app identifiers, monitoring owners, privacy/consent rules and signing/CI access.

The Flutter app calls authenticated APIs. It must never connect directly to the production database or carry server credentials.

## Integration map

Every area below uses the shared composition root above. Method signatures and models linked here are authoritative; pagination and transport schemas are backend decisions, not currently exposed as cursors in the delivered list interfaces.

### Authentication and recovery

Contract: [AuthRepository](../lib/features/authentication/domain/auth_repository.dart). Registered implementation: [MockAuthRepository](../lib/features/authentication/data/mock_auth_repository.dart).

`signIn(email, password)` and `socialSignIn(provider)` return `Result<AppUser>`. `registerLandowner(LandownerRegistration)` also returns a user. Investor signup is `beginInvestorRegistration(InvestorRegistration) -> Result<String>` challenge ID, `verifyInvestorRegistration(challengeId, code) -> Result<void>`, then `completeInvestorRegistration(challengeId) -> Result<AppUser>`; cancellation accepts `Cancellation`, with `cancelInvestorRegistration` and `clearSession` cleanup. Recovery methods request an email challenge, verify a code and reset a password, each returning `Result<void>`.

Backend work: agreed credentials/challenges, real social provider tokens, challenge expiry/rate limits, validation fields and token issuance. The current registration and recovery calls do not prove an identity or send messages. Keep auth errors safe and distinguish invalid input from expired/forbidden/transport failure. No pagination applies.

Prove replacement with [authentication tests](../test/investor_authentication_test.dart), [signup tests](../test/investor_signup_test.dart), [mock login/session tests](../test/qa_login_test.dart) and [native auth journey](../integration_test/investor_auth_flow_test.dart). Add staging tests for expired challenge, wrong/used OTP, cancellation, duplicate submission, revoked session and refresh races.

### User, accounts and selected entities

Contracts: [AppUser / EntityType / Experience](../lib/features/shared/domain/app_user.dart), [SessionService](../lib/core/services/session_service.dart), [InvestorAccountContext](../lib/features/investor/domain/investor_account_context.dart), and `ProfileRepository.load/update`. `selectEntity(entity, nonResident: ...)` changes local scope; `isCurrent(InvestorScope)` rejects stale results. `InvestorAccountRepository.snapshot()` returns `Result<InvestorAccountSnapshot>`.

Backend work: authorized account/entity catalogue, selected membership, profile and residency data, roles and resource-level authorization. Derive protected ownership from authentication and validate every supplied entity/resource identifier. A portal switch is not a new login. Current selected-entity state is not proof of membership. Introduce pagination only if the membership catalogue needs it, with stable IDs and selection invalidation.

Prove with [context tests](../test/investor_context_test.dart), [account repository tests](../test/investor_account_repository_test.dart) and [routing tests](../test/investor_routing_test.dart): change entity during load, logout during a write, restore a session and reject inaccessible IDs without leaking another entity's data.

### Investor catalogue, favourites and search

Contract: [InvestorCatalogRepository](../lib/features/investor/domain/investor_repository.dart). Implementation: [MockInvestorCatalogRepository](../lib/features/investor/data/mock_investor_catalog_repository.dart). `projects() -> Result<List<InvestorProject>>`, `project(id) -> Result<InvestorProject>`, `currentProject(id) -> InvestorProject?`; `changes` is a stream. Favourites use `favouriteIds` and `setFavourite(id, bool) -> Result<void>`; searches use `recentSearches`, `suggestedProjectIds` and `rememberSearch(query)`. `asOf` is the mock catalogue reference date.

Backend work: authoritative project IDs, currency, annual basis-point rate, term/cadence, minimum/capacity/status, filters and stable ordering. Agree cursor pagination before replacing a full-list contract; do not silently drop later pages. Preserve empty results and not-found/forbidden distinctions. Favourites are entity-scoped and need optimistic rollback and last-intent protection. `currentProject` is a local read model, not a network call.

Prove with [filter tests](../test/project_filter_test.dart), [search journey](../test/investor_search_journey_test.dart), [home journey](../test/investor_home_journey_test.dart) and [stores tests](../test/investor_stores_test.dart), including out-of-order favourite responses and scope changes.

### Project details, updates and documents

Models: [InvestorProject](../lib/features/investor/domain/investor_project.dart) and [mock project content](../lib/features/investor/data/mock_project_content.dart), loaded by the catalogue interface. `InvestorProjectDetailStore` also resolves investment IDs through the account repository. Documents and updates are model content; there is no production download/upload adapter behind the local preview UI.

Backend work: authorized project/update/document IDs, published versions, availability/status, MIME type/size, safe titles, expiry and signed object access or authenticated streaming. Define gallery content and update pagination; separate unavailable, expired, loading and empty states. Agree download progress/cancellation, malware checks and file retention server-side. Never use a raw client path as object ownership evidence.

Prove with [client review fidelity tests](../test/client_review_fidelity_test.dart), [project/document journeys](../test/client_review_journey_test.dart) and [critical journeys](../test/investor_critical_journey_test.dart). Test empty/long/unavailable files, changed project during loading and denied/expired access.

### Quotes and investment execution

Contracts/models: `InvestorAccountRepository.invest`, `InvestorCatalogRepository.contribute`, [InvestmentProjection / InvestmentPolicy](../lib/features/investor/domain/investment_policy.dart), [InvestmentStore](../lib/features/investor/presentation/stores/investment_store.dart) and [InvestorDrafts](../lib/features/investor/domain/investor_drafts.dart). The account implementation is [MockInvestorAccountRepository](../lib/features/investor/data/mock_investor_account_repository.dart).

`invest` takes `InvestorProject`, `MonetaryAmount`, `operationId`, `pin`, optional `InvestmentProjection quote` and the demo-only `simulateBiometric` flag, returning `Result<InvestorOperationReceipt>`. `newOperationId()` generates process-local mock IDs. `contribute(id, amount) -> Result<void>` changes local catalogue capacity synchronously. It is not an independent production financial endpoint. A projection carries no server quote ID, expiry or signature today.

Backend work: quote creation/revalidation, quote ID/expiry, exact transport amounts, minimum/maximum and capacity, KYC eligibility, challenge/PIN or provider authorization and atomic investment execution. Allocate robust server-supported idempotency keys and bind keys to the authenticated user/entity and request fingerprint. Concurrent requests and capacity changes after authorization must never overfund a project. Return authoritative transaction/holding IDs and status; keep the UI journey's project/amount/quote together. Retry an uncertain write only using the same backend-supported key and reconcile its result.

Prove with [transaction tests](../test/investor_transaction_test.dart), [client correction tests](../test/client_review_corrections_test.dart), [policy tests](../test/client_review_policy_test.dart) and [critical journey](../test/investor_critical_journey_test.dart). Exercise fully funded and minimum guards, stale quote, post-PIN capacity change, duplicate/replayed requests, changed key payload, insufficient funds and account switch while pending.

### Wallet, deposits, withdrawals and payment methods

Same account contract/implementation. `snapshot()` provides balances, payment methods and account state. `addMoney`/`withdraw` take `MonetaryAmount`, `methodId`, `operationId`, `pin`, optional simulated biometrics and return `Result<InvestorOperationReceipt>`. `addCard` takes card details and `reusable`; `addBankAccount` takes bank/account/type/branch/holder fields and returns `Result<InvestorPaymentMethod>`. Methods also remove/set a default payment method.

Backend work: provider tokenization, approved payment-method setup/verification, pending/failed/settled transitions, fees and available balance. Current raw card fields serve simulated UI validation; agree a compliant provider flow so sensitive card values do not enter general logs or storage. Fee behavior in [investor_transfer_fees.dart](../lib/features/investor/domain/investor_transfer_fees.dart) is a mock assumption (including R1.50 withdrawal fee), not approved server policy. List contracts currently return snapshots; agree scalable pagination if needed. No optimistic notification proves settlement.

Prove with [payment-method tests](../test/investor_payment_methods_test.dart), [account tests](../test/investor_account_repository_test.dart), [transaction tests](../test/investor_transaction_test.dart) and the [client journey](../test/helpers/client_review_journey.dart). Cover unavailable methods, fee affordability, duplicate writes, pending settlement and status reconciliation.

### Transactions, receipts, holdings and portfolio

`transaction(id)`, `investment(id)` and `snapshot()` return the [InvestorTransaction / InvestorInvestment / InvestorAccountSnapshot models](../lib/features/investor/domain/investor_account.dart). Receipt writes return `InvestorOperationReceipt`; rows carry signed transaction amounts, fees, timestamps, references, status and optional recorded project terms. Current receipt presentation uses local models, not an authoritative signed PDF service.

Backend work: stable IDs, UTC timestamps, cursor pagination/filtering, financial reconciliation, recorded schedules/milestones and whether principal remains held. Confirm positive/negative amount conventions and currency. Home total is available wallet plus distinct held principal; projected payouts must not become additional capital. Monthly simple-interest previews do not rewrite historical quarterly schedules. Separate aggregate proceeds, earned-to-date, principal return and final maturity cash, and avoid duplicate credits or immediate-income promises.

Prove with [portfolio analytics](../test/portfolio_analytics_test.dart), [monetary arithmetic](../test/monetary_amount_test.dart), [home journey](../test/investor_home_journey_test.dart) and [transaction tests](../test/investor_transaction_test.dart). Add reconciled server examples for partial settlement, reversal, delayed distributions and matured principal.

### KYC: Individual, Company, Trust and Stokvel

Contract: [KycRepository](../lib/features/investor/domain/kyc/kyc_repository.dart). Implementation: [MockKycRepository](../lib/features/investor/data/mock_kyc_repository.dart). Models/requirements: [kyc_models.dart](../lib/features/investor/domain/kyc/kyc_models.dart), [kyc_plan.dart](../lib/features/investor/domain/kyc/kyc_plan.dart), [EntityType](../lib/features/shared/domain/app_user.dart).

`load(entity) -> Future<Result<KycDraft>>`; `save(draft)` is synchronous. `upload(entity, key, name, bytes, mimeType, cancellation, append, documentId)` and `uploadMemberDocument(...)` return draft results; metadata is simulated and no actual bytes are transported. Delete/save member, allocation and member-draft operations return `Result<KycDraft>`. `invite`, `requestResolutionSignatures`, `submit`, `simulateResolutionSignature`, `simulateRequirementApproval` and `simulateReview` return future draft results. Simulation methods are not acceptable production approvals.

Individual: identity, contact, address, financial/tax and supporting evidence. Company: organisation/representative/member/shareholding information and documents. Trust: trustees, allocations, resolution/signature workflow and supporting evidence. Stokvel: organisation and membership/role/allocation evidence. Use the typed plan's current required field/step keys and saved state; agree provider mapping and compliance rules for all four rather than inferring approval from UI completion counts.

Backend work: durable entity drafts/revisions, upload bytes and type/size validation, secure document IDs, cancellation/retry, provider sessions, authorized invitations/signatures, review/correction status, retention/deletion and authenticated callbacks. Saved changes invalidate related requirement approvals. Local confirmation does not prove identity, review completion or a signature. Extend sync local-edit contracts deliberately for remote persistence/conflict handling. Member/document lists need agreed limits or pagination.

Prove with [KYC tests](../test/investor_kyc_test.dart), [member tests](../test/investor_member_test.dart), [resolution tests](../test/investor_resolution_test.dart), [supporting documents tests](../test/investor_supporting_documents_test.dart), [upload tests](../test/investor_document_upload_test.dart) and [native verification](../integration_test/investor_verification_test.dart). Preserve all four entity journeys, allocation guards, replace/delete/multi-document behavior, failed/retried uploads and scope cancellation.

### Notifications, profile and security

Investor notification methods are `notification(id)` and `markNotificationsRead([id])` on the account repository. Landowner uses [NotificationRepository](../lib/features/notifications/domain/notification_repository.dart), registered to [MockNotificationRepository](../lib/features/notifications/data/mock_notification_repository.dart): `list`, `markRead`, `markAllRead`, `messages`, `sendLocalMessage` return `Result` models/lists. Chat is local and sends nothing externally.

[ProfileRepository](../lib/features/profile/domain/profile_repository.dart), registered to [MockProfileRepository](../lib/features/profile/data/mock_profile_repository.dart), supplies `load/update`, `preferences/updatePreferences`, `payoutAccount/updatePayout`, `securityPreferences/saveSecurityPreferences` and `updateSecurity(action, pin)`. Its security/previous-device values are simulated. [TransactionAuthorization](../lib/core/services/transaction_authorization.dart) is a synchronous mock PIN/biometric abstraction, not a secure server authority.

Backend work: unread counts, stable notification/message IDs, cursor pagination, preferences and channel/topic opt-out, authorized profile updates and audited security/device operations. Agree asynchronous real MFA/PIN/device revocation flows; never send a `simulateBiometric` or `simulateReview` bypass as authority. See [notifications and installation registration](OBSERVABILITY_AND_NOTIFICATIONS.md).

Prove with [security-state tests](../test/security_state_test.dart), [profile-security tests](../test/investor_profile_security_test.dart), [notification tests](../test/notifications_fidelity_test.dart) and [profile tests](../test/profile_fidelity_test.dart). Test logout cleanup, masking semantics, unread state and inaccessible notification targets.

### Landowner properties, submissions, documents, earnings and payouts

Contract: [LandownerRepository](../lib/features/landowner/domain/landowner_repository.dart). Implementation: [MockLandownerRepository](../lib/features/landowner/data/mock_landowner_repository.dart). `overview -> Result<LandownerOverview>`, `properties -> Result<List<Property>>`, `property(id) -> Result<Property>`, `earnings -> Result<EarningsSummary>`. `readDraft(id)` and `saveDraft(SubmissionDraft)` are synchronous local operations; `submit(draft) -> Result<String>` returns the created local property ID. `changes` and balance visibility streams synchronize independent stores. Models: [property.dart](../lib/features/landowner/domain/property.dart), [SubmissionDraft / LocalAttachment](../lib/features/landowner/domain/submission_draft.dart).

Backend work: authorized property ownership, stable draft/property/document IDs, resumable/versioned drafts, actual file transfer, review/offer/status transitions, pagination and server validation. `LocalAttachment` carries sample metadata; no upload bytes or document service is implemented. Financial form strings require validated precise decimal transport and approved server conversion. Earnings summaries are fixture read models, not settlement. Payout account editing uses shared `ProfileRepository.updatePayout(PayoutAccount)`; add server verification, payout execution/status and reconciliation contracts explicitly.

Prove with [submission tests](../test/submission_fidelity_test.dart), [stores tests](../test/stores_test.dart), [payout tests](../test/payout_fidelity_test.dart), [dashboard tests](../test/dashboard_fidelity_test.dart) and [native Landowner journey](../integration_test/landowner_flow_test.dart). Test resume/back/portal switching, repeated submit, missing documents, failed writes and expired sessions without losing or misattributing server drafts.

## Small adapter example (proposal)

This is a **method-level illustration** matching the real `InvestorCatalogRepository.projects()` return type. It is not a complete implementation of that interface. The endpoint path and decoder must be supplied from agreed backend contracts; no endpoint is invented or added to the app.

```dart
final class CatalogueReadAdapter {
  CatalogueReadAdapter(this.client, this.agreedPath, this.decodeProjects);

  final ApiClient client;
  final String agreedPath;
  final List<InvestorProject> Function(Object?) decodeProjects;

  Future<Result<List<InvestorProject>>> projects() {
    return client.request<List<InvestorProject>>(
      path: agreedPath,
      decode: decodeProjects,
    );
  }
}
```

The complete adapter must also implement scope cancellation, current read models, streams, favourites/search behavior and safe disposal, and make pagination explicit. For these Dart types, see [ApiClient](../lib/core/network/api_client.dart) and [catalogue contract](../lib/features/investor/domain/investor_repository.dart). Keep store constructors unchanged where the existing contract suffices.

## Transport, authorization and settlement rules

`ApiClient` requires an HTTPS base and a local absolute request path; it disallows request authorities/schemes and redirects. It uses 15/20/30-second connect/send/receive timeouts, optional bearer attachment, `CancelToken`, typed [error mapping](../lib/core/network/api_error_mapper.dart) and safe method-only debug logging. GET/HEAD can retry once after 200 ms for selected connection failures or 502/503/504; other methods receive one attempt. Keep these restrictions. Single-flight token refresh, refresh rotation, coordinated expiry/revocation cleanup and server error-field decoding are still to be implemented. Token read failure is unauthenticated; the server must reject missing/invalid credentials.

Agree integer cents versus strictly validated decimal-string transport, currency code, basis points and rounding before decoding money. Do not introduce binary floating-point ledger arithmetic. The server owns balances, quotes/rates/fees, capacity, KYC eligibility, settlement and final authorization. UI disabling protects a journey, not an account.

Provider webhooks require authenticated signature verification, replay protection, idempotency and reconciliation on the backend. Handle pending/failed/cancelled/settled states explicitly. Never infer settlement from push payloads, optimistic screens or a local authorization result. Reconcile uncertain writes and reserve capacity atomically with execution.

## Accepted behavior and production decisions

The accepted UI remains intact: Rand/ZAR, R1 minimum, monthly new-project projections, 36-month policy, literal masks, Total Earnings to date and the compact calculator banner. These are not reopened as unresolved visual decisions.

Production input is still needed for canonical catalogue/gallery content and rates, the final withdrawal fee policy, legally approved copy/timing, Trust signature/provider rules and content selection for Home promotions. Runtime currently shows one calculator promotion; an alternate portfolio variant remains available in source. Runtime Trust counts reflect saved valid records rather than contradictory sample counts. Aggregate proceeds and maturity labels need a consistent server/read-model vocabulary. These inputs should refine live data/contracts while preserving accepted presentation.

## Recommended implementation order

1. Confirm environments, contracts, authentication and entity authorization.
2. Connect authentication/profile and one read-only catalogue journey.
3. Connect wallet/account/portfolio read models and reconciliation.
4. Connect KYC and Landowner drafts/documents/submissions.
5. Connect server quotes, transaction authorization and financial writes.
6. Connect installation registration, notifications, monitoring and release controls.
7. Run integration, security and failure-path tests in staging before production.

For each replacement, rerun the full maintained suite and add contract tests against agreed staging responses. Prove authorization and concurrent/idempotent financial behavior server-side; passing Flutter tests alone cannot establish those properties.
