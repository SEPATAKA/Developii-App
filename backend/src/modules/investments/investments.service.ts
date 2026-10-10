import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  InvestmentStatus,
  TransactionKind,
  TransactionStatus,
  VerificationStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { LedgerService } from '../ledger/ledger.service';
import { UsersService } from '../users/users.service';
import { parseAmountCents } from './amount-cents';

@Injectable()
export class InvestmentsService {
  constructor(
    private prisma: PrismaService,
    private ledger: LedgerService,
    private users: UsersService,
    private config: ConfigService,
  ) {}

  async createQuote(
    userId: string,
    projectId: string,
    amountCents: number,
    entityType?: string,
  ) {
    if (amountCents < 100) {
      throw new BadRequestException('Minimum investment is R1.00.');
    }
    const entity = await this.users.resolveEntity(userId, entityType);
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
    });
    if (!project || project.status !== 'open') {
      throw new NotFoundException('Project is not available.');
    }
    const remaining = project.capacityCents - project.fundedCents;
    if (BigInt(amountCents) > remaining) {
      throw new BadRequestException('Amount exceeds remaining capacity.');
    }
    if (BigInt(amountCents) < project.minInvestCents) {
      throw new BadRequestException('Amount is below project minimum.');
    }
    const ttl = Number(this.config.get('QUOTE_TTL_MINUTES', 10));
    const quote = await this.prisma.investmentQuote.create({
      data: {
        entityId: entity.id,
        projectId,
        amountCents: BigInt(amountCents),
        rateBps: project.annualRateBps,
        termMonths: project.termMonths,
        expiresAt: new Date(Date.now() + ttl * 60 * 1000),
      },
    });
    return {
      id: quote.id,
      projectId,
      amountCents,
      rateBps: quote.rateBps,
      termMonths: quote.termMonths,
      expiresAt: quote.expiresAt.toISOString(),
    };
  }

  async invest(input: {
    userId: string;
    projectId: string;
    amountCents: number;
    operationId: string;
    pin: string;
    quoteId?: string;
    entityType?: string;
  }) {
    await this.users.verifyPin(input.userId, input.pin);
    const entity = await this.users.resolveEntity(
      input.userId,
      input.entityType,
    );
    if (entity.verificationStatus !== VerificationStatus.verified) {
      throw new BadRequestException('KYC verification is required to invest.');
    }
    const existing = await this.prisma.transaction.findFirst({
      where: { entityId: entity.id, idempotencyKey: input.operationId },
    });
    if (existing) {
      return {
        transactionId: existing.id,
        investmentId: existing.investmentId,
        status: existing.status,
        reference: existing.reference,
      };
    }

    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.findUnique({
        where: { id: input.projectId },
      });
      if (!project || project.status !== 'open') {
        throw new BadRequestException('Project is not available.');
      }
      let amount = BigInt(input.amountCents);
      let rateBps = project.annualRateBps;
      let termMonths = project.termMonths;
      if (input.quoteId) {
        const quote = await tx.investmentQuote.findUnique({
          where: { id: input.quoteId },
        });
        if (
          !quote ||
          quote.entityId !== entity.id ||
          quote.projectId !== input.projectId ||
          quote.consumedAt ||
          quote.expiresAt < new Date()
        ) {
          throw new BadRequestException('Investment quote is invalid or expired.');
        }
        amount = quote.amountCents;
        rateBps = quote.rateBps;
        termMonths = quote.termMonths;
        await tx.investmentQuote.update({
          where: { id: quote.id },
          data: { consumedAt: new Date() },
        });
      }
      const remaining = project.capacityCents - project.fundedCents;
      if (amount > remaining) {
        throw new BadRequestException('Project capacity exceeded.');
      }
      const wallet = await this.ledger.ensureWallet(entity.id);
      const balance = await this.ledger.balanceCents(wallet.id);
      // Re-read balance inside transaction via last entry
      const last = await tx.ledgerEntry.findFirst({
        where: { accountId: wallet.id },
        orderBy: { createdAt: 'desc' },
      });
      const available = last?.balanceAfter ?? balance;
      if (available < amount) {
        throw new BadRequestException('Insufficient wallet balance.');
      }

      const investment = await tx.investment.create({
        data: {
          entityId: entity.id,
          projectId: project.id,
          amountCents: amount,
          rateBps,
          termMonths,
          status: InvestmentStatus.active,
          quoteId: input.quoteId,
          milestones: {
            create: [
              {
                stage: 'confirmed',
                title: 'Investment confirmed',
                completedAt: new Date(),
                amountCents: amount,
              },
              {
                stage: 'foundation',
                title: 'Project underway',
                dueAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
              },
              {
                stage: 'matured',
                title: 'Maturity',
                dueAt: new Date(
                  Date.now() + termMonths * 30 * 24 * 60 * 60 * 1000,
                ),
                amountCents: amount,
              },
            ],
          },
        },
      });

      const reference = `INV-${randomUUID().slice(0, 8).toUpperCase()}`;
      const createdTx = await tx.transaction.create({
        data: {
          entityId: entity.id,
          kind: TransactionKind.investment,
          status: TransactionStatus.successful,
          amountCents: amount,
          reference,
          idempotencyKey: input.operationId,
          projectId: project.id,
          investmentId: investment.id,
        },
      });

      const held = await this.ledger.ensureTypedAccount(
        'heldPrincipal',
        tx,
      );
      await this.ledger.postEntries(tx, [
        {
          accountId: wallet.id,
          amountCents: -amount,
          transactionId: createdTx.id,
          memo: 'Investment debit',
        },
        {
          accountId: held.id,
          amountCents: amount,
          transactionId: createdTx.id,
          memo: 'Investment principal held',
        },
      ]);

      const funded = project.fundedCents + amount;
      await tx.project.update({
        where: { id: project.id },
        data: {
          fundedCents: funded,
          status: funded >= project.capacityCents ? 'funded' : 'open',
        },
      });

      await tx.notification.create({
        data: {
          userId: input.userId,
          entityId: entity.id,
          title: 'Investment confirmed',
          body: `Your investment of R${(Number(amount) / 100).toFixed(2)} was confirmed.`,
          kind: 'investment',
          payload: { investmentId: investment.id, projectId: project.id },
        },
      });

      return {
        transactionId: createdTx.id,
        investmentId: investment.id,
        status: createdTx.status,
        reference,
        amountCents: Number(amount),
        receiptId: createdTx.id,
      };
    });
  }

  async adminAllocate(input: {
    adminId: string;
    investorNumber: string;
    projectId: string;
    amountCents: number;
    idempotencyKey: string;
  }) {
    const amountCents = parseAmountCents(input.amountCents);
    const investorNumber = input.investorNumber.trim();
    if (!/^\d{7}$/.test(investorNumber)) {
      throw new BadRequestException('Investor ID must be seven digits.');
    }
    const user = await this.prisma.user.findUnique({
      where: { investorNumber },
    });
    if (!user) throw new NotFoundException('Investor was not found.');
    const entity = await this.users.resolveEntity(user.id);
    if (entity.verificationStatus !== VerificationStatus.verified) {
      throw new BadRequestException(
        'Investor must be verified before funds can be allocated.',
      );
    }
    const existing = await this.prisma.transaction.findFirst({
      where: { entityId: entity.id, idempotencyKey: input.idempotencyKey },
    });
    if (existing) return this.mapAdminAllocation(existing.id);

    try {
      return await this.prisma.$transaction(async (tx) => {
        const project = await tx.project.findUnique({
          where: { id: input.projectId },
        });
        if (!project || project.status !== 'open') {
          throw new BadRequestException('Project is not open for allocation.');
        }
        const amount = BigInt(amountCents);
        if (amount < project.minInvestCents) {
          throw new BadRequestException('Amount is below the project minimum.');
        }
        const remaining = project.capacityCents - project.fundedCents;
        if (amount > remaining) {
          throw new BadRequestException('Amount exceeds remaining capacity.');
        }
        const wallet = await this.ledger.ensureWallet(entity.id);
        const last = await tx.ledgerEntry.findFirst({
          where: { accountId: wallet.id },
          orderBy: { createdAt: 'desc' },
        });
        const available = last?.balanceAfter ?? 0n;
        if (available < amount) {
          throw new BadRequestException(
            'Investor does not have enough available wallet balance.',
          );
        }

        const investment = await tx.investment.create({
          data: {
            entityId: entity.id,
            projectId: project.id,
            amountCents: amount,
            rateBps: project.annualRateBps,
            termMonths: project.termMonths,
            status: InvestmentStatus.active,
            milestones: {
              create: [
                {
                  stage: 'confirmed',
                  title: 'Allocated by admin',
                  completedAt: new Date(),
                  amountCents: amount,
                },
              ],
            },
          },
        });
        const reference = `ALC-${randomUUID().slice(0, 8).toUpperCase()}`;
        const createdTx = await tx.transaction.create({
          data: {
            entityId: entity.id,
            kind: TransactionKind.investment,
            status: TransactionStatus.successful,
            amountCents: amount,
            reference,
            idempotencyKey: input.idempotencyKey,
            projectId: project.id,
            investmentId: investment.id,
            metadata: { source: 'admin', adminId: input.adminId },
          },
        });
        const held = await this.ledger.ensureTypedAccount('heldPrincipal', tx);
        await this.ledger.postEntries(tx, [
          {
            accountId: wallet.id,
            amountCents: -amount,
            transactionId: createdTx.id,
            memo: 'Admin allocation debit',
          },
          {
            accountId: held.id,
            amountCents: amount,
            transactionId: createdTx.id,
            memo: 'Admin allocation principal held',
          },
        ]);
        const funded = project.fundedCents + amount;
        await tx.project.update({
          where: { id: project.id },
          data: {
            fundedCents: funded,
            status: funded >= project.capacityCents ? 'funded' : 'open',
          },
        });
        await tx.auditLog.create({
          data: {
            actorAdminId: input.adminId,
            action: 'investment.allocate',
            resource: 'investment',
            resourceId: investment.id,
            metadata: {
              investorNumber,
              projectId: project.id,
              amountCents: amountCents,
            },
          },
        });
        await tx.notification.create({
          data: {
            userId: user.id,
            entityId: entity.id,
            title: 'Funds allocated',
            body: `R${(amountCents / 100).toFixed(2)} was allocated to ${project.name}.`,
            kind: 'investment',
            payload: { investmentId: investment.id, projectId: project.id },
          },
        });
        return {
          investmentId: investment.id,
          transactionId: createdTx.id,
          reference,
          amountCents,
          investorNumber,
          projectName: project.name,
          status: createdTx.status,
        };
      });
    } catch (error) {
      if (
        error &&
        typeof error === 'object' &&
        'code' in error &&
        error.code === 'P2002'
      ) {
        const raced = await this.prisma.transaction.findFirst({
          where: { entityId: entity.id, idempotencyKey: input.idempotencyKey },
        });
        if (raced) return this.mapAdminAllocation(raced.id);
      }
      throw error;
    }
  }

  async adminListAllocations() {
    const rows = await this.prisma.investment.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        project: { select: { name: true, town: true } },
        entity: {
          select: {
            user: { select: { name: true, investorNumber: true } },
          },
        },
      },
    });
    return rows.map((row) => ({
      id: row.id,
      amountCents: Number(row.amountCents),
      status: row.status,
      createdAt: row.createdAt.toISOString(),
      projectName: row.project.name,
      town: row.project.town,
      investorName: row.entity.user.name,
      investorNumber: row.entity.user.investorNumber,
    }));
  }

  private async mapAdminAllocation(transactionId: string) {
    const row = await this.prisma.transaction.findUniqueOrThrow({
      where: { id: transactionId },
      include: { entity: { include: { user: true } } },
    });
    const project = row.projectId
      ? await this.prisma.project.findUnique({ where: { id: row.projectId } })
      : null;
    return {
      investmentId: row.investmentId,
      transactionId: row.id,
      reference: row.reference,
      amountCents: Number(row.amountCents),
      investorNumber: row.entity.user.investorNumber,
      projectName: project?.name ?? '',
      status: row.status,
    };
  }
}
