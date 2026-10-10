# Developify Platform

Production backend, admin dashboard, and Flutter API integration for Developify Mobile.

## Layout

| Path | Role |
| --- | --- |
| `developify-mobile/` | Accepted Flutter app (UI preserved). Mock repos by default; API adapters when `MOCK_MODE=false` |
| `backend/` | NestJS API + Prisma + PostgreSQL |
| `admin/` | Next.js operations dashboard |
| `docs/platform/` | Platform runbooks |

## Quick start (local)

### 1. Infrastructure

```sh
cd backend
docker compose up -d postgres redis minio mailhog
```

### 2. API

```sh
cd backend
cp .env.example .env   # or use committed .env for local defaults
npm install
npx prisma migrate deploy
npm run prisma:seed
npm run start:dev
```

API: `http://localhost:3000/v1`  
Swagger: `http://localhost:3000/docs`  
Mailhog UI: `http://localhost:8025`

Seeded accounts:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@developify.co.za` | `Developify@Admin1` |
| Investor | `investor.qa@developify.co.za` | `Developify@123` (PIN `1234`, investor ID `1000001`) |
| Landowner | `landowner.qa@developify.co.za` | `Developify@123` (investor ID `1000002`) |

### 3. Admin

```sh
cd admin
npm install
npm run dev -- --port 3001
```

Open `http://localhost:3001` and sign in with the admin credentials.

### 4. Flutter (live API)

```sh
cd developify-mobile
flutter run --target lib/main.dart \
  --dart-define=MOCK_MODE=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=FIREBASE_ENABLED=false \
  --dart-define=TELEMETRY_ENABLED=false \
  --dart-define=ONESIGNAL_APP_ID=
```

Use `http://localhost:3000` on iOS simulator / desktop, or `http://10.0.2.2:3000` on Android emulator.

Keep `MOCK_MODE=true` (default) for offline demo and the maintained test suite.

## Security notes

- Access JWT + rotating refresh tokens
- Argon2id password hashes
- Rate-limited auth/OTP
- Financial writes require PIN and idempotency keys
- Cards are not stored (Paystack adapter stub)
- KYC review is admin-driven (Smile ID adapter stub)
- Audit log for admin and financial actions

## Provider adapters (Phase 1 stubs)

- `PaymentProvider` → `ManualPaymentProvider` (EFT + admin confirm)
- `ManualKycProvider` → admin queue approve/correct

Swap implementations when provider credentials are available. Until then the admin integration status is **not configured**. A sandbox check must stay labelled synthetic and must not authorise a real-money deposit or investment.

Wallet funding (`POST` add-money) is rejected unless the investor entity `verificationStatus` is `verified`. A pending top-up is not a cleared deposit. The deposit reference is the seven-digit investor ID plus a short suffix so the unique transaction reference can repeat for the same investor. Admin deposit confirmation is still a manual control, not a bank callback.

New ledger batches must balance to zero cents. The existing seed credits the QA wallet with a single-sided entry; correct that with an authorised reversing pair rather than editing the posted row.

`GET /admin/users` returns investor ID and verification status and omits password and PIN hashes.

## Production blockers (28 Sep 2026)

These were checked in this workspace and are still open:

- Docker was not running, so `prisma migrate deploy` could not apply `20260928130000_investor_number`.
- Mobile still defaults to `MOCK_MODE=true`.
- Privileged MFA, maker-checker, and roles beyond admin / ops / compliance are not implemented.
- Live KYC, card payments, and SMS providers have no credentials and no verified webhooks.
- Regulatory classification (POPIA, FICA, FSCA / CIS / FAIS, e-signatures) is not established by this software.
