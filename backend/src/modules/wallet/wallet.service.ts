import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  InvestmentStatus,
  PaymentMethodKind,
  TransactionKind,
  TransactionStatus,
  VerificationStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { LedgerService } from '../ledger/ledger.service';
import { UsersService } from '../users/users.service';
import { PaymentService } from '../payments/payment.service';

@Injectable()
export class WalletService {
  constructor(
    private prisma: PrismaService,
    private ledger: LedgerService,
    private users: UsersService,
    private payments: PaymentService,
    private config: ConfigService,
  ) {}

  private mapTx(t: {
    id: string;
    kind: TransactionKind;
    status: TransactionStatus;
    amountCents: bigint;
    feeCents: bigint;
    currency: string;
    reference: string;
    projectId: string | null;
    investmentId: string | null;
    createdAt: Date;
  }) {
    return {
      id: t.id,
      kind: t.kind,
      status: t.status,
      amountCents: Number(t.amountCents),
      feeCents: Number(t.feeCents),
      currency: t.currency,
      reference: t.reference,
      projectId: t.projectId,
      investmentId: t.investmentId,
      createdAt: t.createdAt.toISOString(),
    };
  }

  private mapInvestment(i: {
    id: string;
    projectId: string;
    amountCents: bigint;
    rateBps: number;
    termMonths: number;
    status: InvestmentStatus;
    principalHeld: boolean;
    createdAt: Date;
    project?: { name: string; town: string };
    milestones?: {
      id: string;
      stage: string;
      title: string;
      dueAt: Date | null;
      completedAt: Date | null;
      amountCents: bigint | null;
    }[];
  }) {
    return {
      id: i.id,
      projectId: i.projectId,
      projectName: i.project?.name,
      town: i.project?.town,
      amountCents: Number(i.amountCents),
      rateBps: i.rateBps,
      termMonths: i.termMonths,
      status: i.status,
      principalHeld: i.principalHeld,
      createdAt: i.createdAt.toISOString(),
      milestones: (i.milestones ?? []).map((m) => ({
        id: m.id,
        stage: m.stage,
        title: m.title,
        dueAt: m.dueAt?.toISOString() ?? null,
        completedAt: m.completedAt?.toISOString() ?? null,
        amountCents: m.amountCents != null ? Number(m.amountCents) : null,
      })),
    };
  }

  async snapshot(userId: string, entityType?: string) {
    const entity = await this.users.resolveEntity(userId, entityType);
    await this.ledger.ensureWallet(entity.id);
    const availableCents = await this.ledger.walletBalanceForEntity(entity.id);
    const investments = await this.prisma.investment.findMany({
      where: { entityId: entity.id },
      include: { project: true, milestones: true },
      orderBy: { createdAt: 'desc' },
    });
    const heldPrincipalCents = investments
      .filter((i) => i.principalHeld && i.status === InvestmentStatus.active)
      .reduce((sum, i) => sum + i.amountCents, 0n);
    const transactions = await this.prisma.transaction.findMany({
      where: { entityId: entity.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    const methods = await this.prisma.paymentMethod.findMany({
      where: { entityId: entity.id },
      orderBy: { createdAt: 'desc' },
    });
    const notifications = await this.prisma.notification.findMany({
      where: { userId, OR: [{ entityId: entity.id }, { entityId: null }] },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return {
      entityId: entity.id,
      entityType: entity.entityType,
      verificationStatus: entity.verificationStatus,
      availableCents: Number(availableCents),
      heldPrincipalCents: Number(heldPrincipalCents),
      currency: 'ZAR',
      investments: investments.map((i) => this.mapInvestment(i)),
      transactions: transactions.map((t) => this.mapTx(t)),
      paymentMethods: methods.map((m) => ({
        id: m.id,
        kind: m.kind,
        name: m.name,
        lastFour: m.lastFour,
        holder: m.holder,
        expiry: m.expiry,
        bankType: m.bankType,
        branchCode: m.branchCode,
        reusable: m.reusable,
        isDefault: m.isDefault,
      })),
      notifications: notifications.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        kind: n.kind,
        read: !!n.readAt,
        createdAt: n.createdAt.toISOString(),
        payload: n.payload,
      })),
      depositInstructions: {
        bank: 'Developify Holdings',
        accountNumber: '6284190219',
        branchCode: '250655',
        holder: 'Developify Holding',
      },
    };
  }

  async getTransaction(userId: string, id: string, entityType?: string) {
    const entity = await this.users.resolveEntity(userId, entityType);
    const tx = await this.prisma.transaction.findFirst({
      where: { id, entityId: entity.id },
    });
    if (!tx) throw new NotFoundException('Transaction not found.');
    return this.mapTx(tx);
  }

  async getInvestment(userId: string, id: string, entityType?: string) {
    const entity = await this.users.resolveEntity(userId, entityType);
    const inv = await this.prisma.investment.findFirst({
      where: { id, entityId: entity.id },
      include: { project: true, milestones: true },
    });
    if (!inv) throw new NotFoundException('Investment not found.');
    return this.mapInvestment(inv);
  }

  async addMoney(input: {
    userId: string;
    amountCents: number;
    methodId: string;
    operationId: string;
    pin: string;
    entityType?: string;
  }) {
    await this.users.verifyPin(input.userId, input.pin);
    if (input.amountCents < 100) {
      throw new BadRequestException('Minimum deposit is R1.00.');
    }
    const entity = await this.users.resolveEntity(
      input.userId,
      input.entityType,
    );
    const existing = await this.prisma.transaction.findFirst({
      where: { entityId: entity.id, idempotencyKey: input.operationId },
    });
    if (existing) return this.mapTx(existing);
    if (entity.verificationStatus !== VerificationStatus.verified) {
      throw new BadRequestException(
        'Complete verification before funding your wallet.',
      );
    }

    const account = await this.prisma.user.findUniqueOrThrow({
      where: { id: input.userId },
      select: { investorNumber: true },
    });
    const suffix = randomUUID().slice(0, 4).toUpperCase();
    const reference = account.investorNumber
      ? `${account.investorNumber}-${suffix}`
      : `DEP-${suffix}`;
    const amount = BigInt(input.amountCents);
    const payment = await this.payments.active.initiateDeposit({
      amountCents: amount,
      reference,
      entityId: entity.id,
    });
    const tx = await this.prisma.transaction.create({
      data: {
        entityId: entity.id,
        kind: TransactionKind.topUp,
        status: TransactionStatus.pending,
        amountCents: amount,
        reference,
        idempotencyKey: input.operationId,
        methodId: input.methodId,
        metadata: payment.instructions,
      },
    });
    return {
      ...this.mapTx(tx),
      instructions: payment.instructions,
    };
  }

  async withdraw(input: {
    userId: string;
    amountCents: number;
    methodId: string;
    operationId: string;
    pin: string;
    entityType?: string;
  }) {
    await this.users.verifyPin(input.userId, input.pin);
    const entity = await this.users.resolveEntity(
      input.userId,
      input.entityType,
    );
    const existing = await this.prisma.transaction.findFirst({
      where: { entityId: entity.id, idempotencyKey: input.operationId },
    });
    if (existing) return this.mapTx(existing);

    const fee = BigInt(this.config.get('WITHDRAWAL_FEE_CENTS', '150'));
    const amount = BigInt(input.amountCents);
    const total = amount + fee;
    const balance = await this.ledger.walletBalanceForEntity(entity.id);
    if (balance < total) {
      throw new BadRequestException('Insufficient available balance.');
    }
    const method = await this.prisma.paymentMethod.findFirst({
      where: { id: input.methodId, entityId: entity.id },
    });
    if (!method) throw new BadRequestException('Payment method not found.');

    const reference = `WDR-${randomUUID().slice(0, 8).toUpperCase()}`;
    await this.payments.active.initiateWithdrawal({
      amountCents: amount,
      reference,
      methodId: input.methodId,
    });

    const wallet = await this.ledger.ensureWallet(entity.id);
    await this.ledger.ensurePlatformAccounts();
    const feeAccount = await this.prisma.ledgerAccount.findFirstOrThrow({
      where: { type: 'feeRevenue' },
    });
    const clearing = await this.prisma.ledgerAccount.findFirstOrThrow({
      where: { type: 'platformClearing' },
    });

    const tx = await this.prisma.$transaction(async (db) => {
      const created = await db.transaction.create({
        data: {
          entityId: entity.id,
          kind: TransactionKind.withdrawal,
          status: TransactionStatus.pending,
          amountCents: amount,
          feeCents: fee,
          reference,
          idempotencyKey: input.operationId,
          methodId: input.methodId,
        },
      });
      await this.ledger.postEntries(db, [
        {
          accountId: wallet.id,
          amountCents: -total,
          transactionId: created.id,
          memo: 'Withdrawal hold',
        },
        {
          accountId: clearing.id,
          amountCents: amount,
          transactionId: created.id,
          memo: 'Withdrawal clearing',
        },
        {
          accountId: feeAccount.id,
          amountCents: fee,
          transactionId: created.id,
          memo: 'Withdrawal fee',
        },
      ]);
      return created;
    });
    return this.mapTx(tx);
  }

  async addBankAccount(
    userId: string,
    data: {
      bank: string;
      accountNumber: string;
      accountType: string;
      branchCode: string;
      holder: string;
      entityType?: string;
    },
  ) {
    const entity = await this.users.resolveEntity(userId, data.entityType);
    const lastFour = data.accountNumber.slice(-4);
    return this.prisma.paymentMethod.create({
      data: {
        userId,
        entityId: entity.id,
        kind: PaymentMethodKind.bankAccount,
        name: data.bank,
        lastFour,
        holder: data.holder,
        bankType: data.accountType,
        branchCode: data.branchCode,
      },
    });
  }

  async addCard() {
    throw new BadRequestException({
      kind: 'configuration',
      message:
        'Card tokenization is not enabled. Use a bank account or configure Paystack.',
    });
  }

  async removePaymentMethod(userId: string, id: string, entityType?: string) {
    const entity = await this.users.resolveEntity(userId, entityType);
    await this.prisma.paymentMethod.deleteMany({
      where: { id, entityId: entity.id },
    });
    return { ok: true };
  }

  async setDefaultPaymentMethod(
    userId: string,
    id: string,
    isDefault: boolean,
    entityType?: string,
  ) {
    const entity = await this.users.resolveEntity(userId, entityType);
    await this.prisma.$transaction(async (tx) => {
      if (isDefault) {
        await tx.paymentMethod.updateMany({
          where: { entityId: entity.id },
          data: { isDefault: false },
        });
      }
      await tx.paymentMethod.updateMany({
        where: { id, entityId: entity.id },
        data: { isDefault },
      });
    });
    return { ok: true };
  }

  async markNotificationsRead(userId: string, id?: string) {
    await this.prisma.notification.updateMany({
      where: {
        userId,
        readAt: null,
        ...(id ? { id } : {}),
      },
      data: { readAt: new Date() },
    });
    return { ok: true };
  }

  async confirmDeposit(adminId: string, transactionId: string) {
    const tx = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });
    if (!tx || tx.kind !== TransactionKind.topUp) {
      throw new NotFoundException('Deposit not found.');
    }
    if (tx.status === TransactionStatus.successful) return this.mapTx(tx);
    const wallet = await this.ledger.ensureWallet(tx.entityId);
    await this.ledger.ensurePlatformAccounts();
    const clearing = await this.prisma.ledgerAccount.findFirstOrThrow({
      where: { type: 'platformClearing' },
    });
    await this.prisma.$transaction(async (db) => {
      await db.transaction.update({
        where: { id: tx.id },
        data: { status: TransactionStatus.successful },
      });
      await this.ledger.postEntries(db, [
        {
          accountId: clearing.id,
          amountCents: -tx.amountCents,
          transactionId: tx.id,
          memo: 'Deposit clearing',
        },
        {
          accountId: wallet.id,
          amountCents: tx.amountCents,
          transactionId: tx.id,
          memo: 'Deposit credit',
        },
      ]);
      await db.auditLog.create({
        data: {
          actorAdminId: adminId,
          action: 'deposit.confirm',
          resource: 'transaction',
          resourceId: tx.id,
        },
      });
    });
    return this.mapTx({ ...tx, status: TransactionStatus.successful });
  }

  async approveWithdrawal(adminId: string, transactionId: string) {
    const tx = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });
    if (!tx || tx.kind !== TransactionKind.withdrawal) {
      throw new NotFoundException('Withdrawal not found.');
    }
    await this.prisma.transaction.update({
      where: { id: tx.id },
      data: { status: TransactionStatus.successful },
    });
    await this.prisma.auditLog.create({
      data: {
        actorAdminId: adminId,
        action: 'withdrawal.approve',
        resource: 'transaction',
        resourceId: tx.id,
      },
    });
    return this.mapTx({ ...tx, status: TransactionStatus.successful });
  }
}
