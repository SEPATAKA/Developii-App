import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { LedgerAccountType, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export function assertBalancedLedger(entries: { amountCents: bigint }[]) {
  const sum = entries.reduce((total, entry) => total + entry.amountCents, 0n);
  if (sum !== 0n) {
    throw new InternalServerErrorException(
      'Ledger batch is not balanced and was not posted.',
    );
  }
}

@Injectable()
export class LedgerService {
  constructor(private prisma: PrismaService) {}

  async ensureWallet(entityId: string) {
    const existing = await this.prisma.ledgerAccount.findUnique({
      where: { entityId },
    });
    if (existing) return existing;
    return this.prisma.ledgerAccount.create({
      data: {
        type: LedgerAccountType.userWallet,
        entityId,
        currency: 'ZAR',
      },
    });
  }

  async ensureTypedAccount(
    type: LedgerAccountType,
    tx: Prisma.TransactionClient = this.prisma,
  ) {
    const found = await tx.ledgerAccount.findFirst({ where: { type } });
    if (found) return found;
    return tx.ledgerAccount.create({
      data: { type, currency: 'ZAR' },
    });
  }

  async ensurePlatformAccounts(tx: Prisma.TransactionClient = this.prisma) {
    const types = [
      LedgerAccountType.platformClearing,
      LedgerAccountType.feeRevenue,
    ] as const;
    for (const type of types) {
      const found = await tx.ledgerAccount.findFirst({ where: { type } });
      if (!found) {
        await tx.ledgerAccount.create({
          data: { type, currency: 'ZAR' },
        });
      }
    }
  }

  async balanceCents(accountId: string): Promise<bigint> {
    const last = await this.prisma.ledgerEntry.findFirst({
      where: { accountId },
      orderBy: { createdAt: 'desc' },
    });
    return last?.balanceAfter ?? 0n;
  }

  async walletBalanceForEntity(entityId: string): Promise<bigint> {
    const account = await this.ensureWallet(entityId);
    return this.balanceCents(account.id);
  }

  async postEntries(
    tx: Prisma.TransactionClient,
    entries: {
      accountId: string;
      amountCents: bigint;
      transactionId?: string;
      memo?: string;
    }[],
  ) {
    assertBalancedLedger(entries);
    for (const entry of entries) {
      const last = await tx.ledgerEntry.findFirst({
        where: { accountId: entry.accountId },
        orderBy: { createdAt: 'desc' },
      });
      const balanceAfter = (last?.balanceAfter ?? 0n) + entry.amountCents;
      await tx.ledgerEntry.create({
        data: {
          accountId: entry.accountId,
          amountCents: entry.amountCents,
          balanceAfter,
          transactionId: entry.transactionId,
          memo: entry.memo ?? '',
        },
      });
    }
  }
}
