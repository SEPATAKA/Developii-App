# Developify security model (phase 1)

## Authentication

- Argon2id password hashes
- Short-lived access JWT + rotating refresh tokens (hashed at rest)
- OTP challenges hashed; attempt limits; TTL from env
- Admin and end-user tokens distinguished by `typ` claim

## Authorization

- Portal membership (`investor` / `landowner`) enforced server-side
- Investor entity scope (`individual` / `company` / `trust` / `stokvel`)
- Admin RBAC: `admin`, `ops`, `compliance`
- Resource ownership checks on every wallet/KYC/property access

## Financial

- Ledger entries in integer cents
- Idempotency keys on invest / deposit / withdraw
- Capacity reserved atomically with investment
- Transaction PIN verified server-side on money writes
- No card PAN/CVV storage; card add rejected until Paystack adapter configured

## Data protection

- Document uploads via short-lived S3/MinIO presigned URLs
- Soft-delete field on documents for retention workflows
- Audit log for admin actions and settlement confirmations
- HTTPS required for non-localhost API base URLs in the mobile client

## Operational

- Rate limiting via Nest Throttler
- CORS locked to `ADMIN_ORIGIN`
- Secrets only via environment variables
