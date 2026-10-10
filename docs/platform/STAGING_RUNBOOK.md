# Staging runbook

## Preflight

1. Postgres, Redis, MinIO (or S3), SMTP reachable
2. `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` rotated (≥32 chars)
3. `ADMIN_ORIGIN` set to admin URL
4. `S3_*` configured for document uploads
5. Seed admin password changed from default

## Deploy

```sh
cd backend
npx prisma migrate deploy
npm run prisma:seed   # first environment only
npm run build && npm run start:prod
```

Admin: `npm run build && npm run start -- --port 3001`

## Smoke checks

1. `POST /v1/auth/admin/sign-in` → admin dashboard loads
2. `POST /v1/auth/sign-in` with seeded investor → wallet snapshot
3. Create deposit → confirm in admin → balance increases
4. Submit KYC → approve in admin → invest succeeds
5. Landowner submit → set status `live` → project appears in catalogue

## Flutter live mode

```sh
--dart-define=MOCK_MODE=false
--dart-define=API_BASE_URL=https://api.your-domain
```

## Rollback

1. Re-enable `MOCK_MODE=true` on mobile builds
2. Restore previous API image / migration down only with explicit DBA approval
