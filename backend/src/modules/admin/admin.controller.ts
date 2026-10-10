import { Body, Controller, Get, Param, Patch, Post, Put } from '@nestjs/common';
import { ProjectStatus, PropertyStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthUser, CurrentUser, Roles } from '../common/auth.decorators';
import { WalletService } from '../wallet/wallet.service';
import { LandownerService } from '../landowner/landowner.service';
import { KycService } from '../kyc/kyc.service';
import { InvestmentsService } from '../investments/investments.service';

@Controller('admin')
export class AdminController {
  constructor(
    private prisma: PrismaService,
    private wallet: WalletService,
    private landowner: LandownerService,
    private kyc: KycService,
    private investments: InvestmentsService,
  ) {}

  @Roles('admin', 'ops', 'compliance')
  @Get('dashboard')
  async dashboard() {
    const [users, pendingKyc, pendingDeposits, pendingWithdrawals, properties, projects] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.kycDraft.count({ where: { status: 'pending' } }),
        this.prisma.transaction.count({
          where: { kind: 'topUp', status: 'pending' },
        }),
        this.prisma.transaction.count({
          where: { kind: 'withdrawal', status: 'pending' },
        }),
        this.prisma.property.count({ where: { status: 'underReview' } }),
        this.prisma.project.count(),
      ]);
    return {
      users,
      pendingKyc,
      pendingDeposits,
      pendingWithdrawals,
      propertiesUnderReview: properties,
      projects,
    };
  }

  @Roles('admin', 'ops', 'compliance')
  @Get('users')
  users() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        locked: true,
        investorNumber: true,
        nonResident: true,
        createdAt: true,
        memberships: { select: { experience: true } },
        entities: {
          select: { entityType: true, verificationStatus: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  @Roles('admin')
  @Patch('users/:id/lock')
  lockUser(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() body: { locked: boolean },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id },
        data: { locked: body.locked },
      });
      await tx.auditLog.create({
        data: {
          actorAdminId: admin.id,
          action: body.locked ? 'user.lock' : 'user.unlock',
          resource: 'user',
          resourceId: id,
        },
      });
      return user;
    });
  }

  @Roles('admin', 'ops')
  @Get('transactions')
  transactions() {
    return this.prisma.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: { entity: { include: { user: true } } },
    });
  }

  @Roles('admin', 'ops')
  @Get('projects')
  async projects() {
    const rows = await this.prisma.project.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((project) => ({
      ...project,
      minInvestCents: project.minInvestCents.toString(),
      capacityCents: project.capacityCents.toString(),
      fundedCents: project.fundedCents.toString(),
    }));
  }

  @Roles('admin', 'ops')
  @Post('projects')
  createProject(
    @CurrentUser() admin: AuthUser,
    @Body()
    body: {
      slug: string;
      name: string;
      town: string;
      description?: string;
      annualRateBps: number;
      termMonths?: number;
      minInvestCents?: number;
      capacityCents: number;
      status?: ProjectStatus;
      imageUrl?: string;
      contentJson?: object;
    },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const project = await tx.project.create({
        data: {
          slug: body.slug,
          name: body.name,
          town: body.town,
          description: body.description ?? '',
          annualRateBps: body.annualRateBps,
          termMonths: body.termMonths ?? 36,
          minInvestCents: BigInt(body.minInvestCents ?? 100),
          capacityCents: BigInt(body.capacityCents),
          status: body.status ?? 'open',
          imageUrl: body.imageUrl,
          contentJson: body.contentJson,
          publishedAt: new Date(),
        },
      });
      await tx.auditLog.create({
        data: {
          actorAdminId: admin.id,
          action: 'project.create',
          resource: 'project',
          resourceId: project.id,
        },
      });
      return {
        ...project,
        minInvestCents: Number(project.minInvestCents),
        capacityCents: Number(project.capacityCents),
        fundedCents: Number(project.fundedCents),
      };
    });
  }

  @Roles('admin', 'ops')
  @Put('projects/:id')
  updateProject(
    @Param('id') id: string,
    @Body() body: Record<string, unknown>,
  ) {
    const data: Record<string, unknown> = { ...body };
    if (typeof body.capacityCents === 'number') {
      data.capacityCents = BigInt(body.capacityCents);
    }
    if (typeof body.minInvestCents === 'number') {
      data.minInvestCents = BigInt(body.minInvestCents);
    }
    return this.prisma.project.update({ where: { id }, data: data as never });
  }

  @Roles('admin', 'ops', 'compliance')
  @Get('audit-logs')
  auditLogs() {
    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  @Roles('admin')
  @Get('config')
  async config() {
    return this.prisma.systemConfig.findMany();
  }

  @Roles('admin')
  @Put('config/:key')
  setConfig(@Param('key') key: string, @Body() body: { value: unknown }) {
    return this.prisma.systemConfig.upsert({
      where: { key },
      create: { key, value: body.value as never },
      update: { value: body.value as never },
    });
  }

  @Roles('admin', 'ops')
  @Get('properties')
  properties() {
    return this.landowner.adminList();
  }

  @Roles('admin', 'ops')
  @Post('properties')
  createProperty(
    @CurrentUser() admin: AuthUser,
    @Body()
    body: {
      ownerEmail?: string;
      investorNumber?: string;
      name: string;
      town: string;
      address?: string;
      erf?: string;
      size?: string;
      status?: PropertyStatus;
    },
  ) {
    return this.landowner.adminCreate(admin.id, body);
  }

  @Roles('admin', 'ops')
  @Get('allocations')
  allocations() {
    return this.investments.adminListAllocations();
  }

  @Roles('admin', 'ops')
  @Post('allocations')
  allocate(
    @CurrentUser() admin: AuthUser,
    @Body()
    body: {
      investorNumber: string;
      projectId: string;
      amountCents: number;
      idempotencyKey: string;
    },
  ) {
    return this.investments.adminAllocate({
      adminId: admin.id,
      investorNumber: body.investorNumber,
      projectId: body.projectId,
      amountCents: body.amountCents,
      idempotencyKey: body.idempotencyKey,
    });
  }

  @Roles('admin', 'ops')
  @Post('properties/:id/status')
  propertyStatus(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() body: { status: PropertyStatus },
  ) {
    return this.landowner.adminSetStatus(admin.id, id, body.status);
  }

  @Roles('admin', 'compliance', 'ops')
  @Get('kyc/queue')
  kycQueue() {
    return this.kyc.adminQueue();
  }

  @Roles('admin', 'ops')
  @Post('wallet/deposits/:id/confirm')
  confirmDeposit(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.wallet.confirmDeposit(admin.id, id);
  }

  @Roles('admin', 'ops')
  @Post('wallet/withdrawals/:id/approve')
  approveWithdrawal(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.wallet.approveWithdrawal(admin.id, id);
  }
}
