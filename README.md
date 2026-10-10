# Developify Platform

Full-stack Developify workspace: accepted Flutter mobile app, NestJS production API, and Next.js admin dashboard.

## Packages

| Directory | Description |
| --- | --- |
| [developify-mobile](developify-mobile/) | Flutter Investor + Landowner app (UI frozen; API adapters added) |
| [backend](backend/) | NestJS + Prisma + PostgreSQL API |
| [admin](admin/) | Next.js admin / ops dashboard |
| [docs/platform](docs/platform/) | Platform setup and staging runbook |

## Default mode

Mobile ships in **mock mode** (`MOCK_MODE=true`) so existing demo behaviour and tests stay intact.

To connect live services, see [docs/platform/README.md](docs/platform/README.md).

## Stack

- **Mobile:** Flutter, MobX, go_router, Dio, GetIt
- **API:** NestJS, Prisma, PostgreSQL, Redis, MinIO, JWT
- **Admin:** Next.js 15 App Router
- **Money:** integer cents (ZAR), idempotent ledger writes
- **Payments / KYC (phase 1):** manual EFT + admin review; provider adapter stubs ready
