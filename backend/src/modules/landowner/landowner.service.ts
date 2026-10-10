import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PropertyStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LandownerService {
  constructor(private prisma: PrismaService) {}

  private mapProperty(p: {
    id: string;
    name: string;
    town: string;
    address: string;
    erf: string;
    size: string;
    status: PropertyStatus;
    fundingPercent: number;
    draftStep: number;
  }) {
    return {
      id: p.id,
      name: p.name,
      town: p.town,
      address: p.address,
      erf: p.erf,
      size: p.size,
      status: p.status,
      fundingPercent: p.fundingPercent,
      draftStep: p.draftStep,
    };
  }

  async overview(userId: string) {
    const properties = await this.prisma.property.findMany({
      where: { ownerId: userId },
      orderBy: { updatedAt: 'desc' },
    });
    const payouts = await this.prisma.landownerPayout.findMany({
      where: { property: { ownerId: userId } },
      orderBy: { paidAt: 'desc' },
    });
    const totalCents = payouts.reduce((s, p) => s + p.amountCents, 0n);
    return {
      properties: properties.map((p) => this.mapProperty(p)),
      earnedCents: Number(totalCents),
      propertyCount: properties.length,
      approvedCount: properties.filter((p) =>
        ['offerReady', 'live'].includes(p.status),
      ).length,
      nextPayoutCents: payouts[0] ? Number(payouts[0].amountCents) : 0,
    };
  }

  async properties(userId: string) {
    const rows = await this.prisma.property.findMany({
      where: { ownerId: userId },
      orderBy: { updatedAt: 'desc' },
    });
    return rows.map((p) => this.mapProperty(p));
  }

  async property(userId: string, id: string) {
    const p = await this.prisma.property.findFirst({
      where: { id, ownerId: userId },
    });
    if (!p) throw new NotFoundException('Property not found.');
    return this.mapProperty(p);
  }

  async earnings(userId: string) {
    const payouts = await this.prisma.landownerPayout.findMany({
      where: { property: { ownerId: userId } },
      orderBy: { paidAt: 'desc' },
    });
    const totalCents = payouts.reduce((s, p) => s + p.amountCents, 0n);
    return {
      totalCents: Number(totalCents),
      nextPayoutCents: payouts[0] ? Number(payouts[0].amountCents) : 0,
      payouts: payouts.map((p) => ({
        id: p.id,
        propertyName: p.propertyName,
        amountCents: Number(p.amountCents),
        period: p.period,
        date: p.paidAt.toISOString().slice(0, 10),
      })),
    };
  }

  async readDraft(userId: string, draftKey: string) {
    const draft = await this.prisma.submissionDraft.findUnique({
      where: { ownerId_draftKey: { ownerId: userId, draftKey } },
      include: { documents: true },
    });
    return draft
      ? {
          id: draft.draftKey,
          step: draft.step,
          payload: draft.payload,
          documents: draft.documents,
        }
      : { id: draftKey, step: 1, payload: {}, documents: [] };
  }

  async saveDraft(
    userId: string,
    draftKey: string,
    step: number,
    payload: object,
  ) {
    const draft = await this.prisma.submissionDraft.upsert({
      where: { ownerId_draftKey: { ownerId: userId, draftKey } },
      create: { ownerId: userId, draftKey, step, payload },
      update: { step, payload },
    });
    return { id: draft.draftKey, step: draft.step, payload: draft.payload };
  }

  async submit(userId: string, draftKey: string) {
    const draft = await this.prisma.submissionDraft.findUnique({
      where: { ownerId_draftKey: { ownerId: userId, draftKey } },
    });
    const payload = (draft?.payload ?? {}) as Record<string, string>;
    const property = await this.prisma.property.create({
      data: {
        ownerId: userId,
        name: payload.name || 'Untitled property',
        town: payload.town || payload.city || '',
        address: payload.address || '',
        erf: payload.erf || payload.number || '',
        size: payload.size ? `${payload.size} ${payload.unit || 'm²'}` : '',
        status: PropertyStatus.underReview,
        draftStep: draft?.step ?? 9,
        metadata: payload,
      },
    });
    return { propertyId: property.id };
  }

  async adminSetStatus(
    adminId: string,
    propertyId: string,
    status: PropertyStatus,
  ) {
    const property = await this.prisma.property.update({
      where: { id: propertyId },
      data: { status },
    });
    if (status === PropertyStatus.live) {
      const existing = await this.prisma.project.findFirst({
        where: { propertyId },
      });
      if (!existing) {
        await this.prisma.project.create({
          data: {
            slug: `prop-${property.id.slice(0, 8)}`,
            name: property.name,
            town: property.town,
            description: `Investment opportunity from ${property.name}`,
            annualRateBps: 1450,
            capacityCents: 500000000n,
            status: 'open',
            publishedAt: new Date(),
            propertyId: property.id,
          },
        });
      }
    }
    await this.prisma.auditLog.create({
      data: {
        actorAdminId: adminId,
        action: `property.${status}`,
        resource: 'property',
        resourceId: propertyId,
      },
    });
    return this.mapProperty(property);
  }

  async adminCreate(
    adminId: string,
    input: {
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
    const email = input.ownerEmail?.toLowerCase().trim();
    const investorNumber = input.investorNumber?.trim();
    if (!email && !investorNumber) {
      throw new BadRequestException(
        'Enter the owner email or seven-digit investor ID.',
      );
    }
    const owner = await this.prisma.user.findFirst({
      where: investorNumber ? { investorNumber } : { email },
      select: { id: true, name: true, email: true },
    });
    if (!owner) {
      throw new NotFoundException(
        'Owner account was not found. Use an existing investor or landowner.',
      );
    }
    const name = input.name.trim();
    const town = input.town.trim();
    if (!name || !town) {
      throw new BadRequestException('Property name and town are required.');
    }
    return this.prisma.$transaction(async (tx) => {
      const property = await tx.property.create({
        data: {
          ownerId: owner.id,
          name,
          town,
          address: input.address?.trim() ?? '',
          erf: input.erf?.trim() ?? '',
          size: input.size?.trim() ?? '',
          status: input.status ?? PropertyStatus.underReview,
        },
      });
      await tx.auditLog.create({
        data: {
          actorAdminId: adminId,
          action: 'property.create',
          resource: 'property',
          resourceId: property.id,
          metadata: { ownerId: owner.id },
        },
      });
      return {
        ...this.mapProperty(property),
        owner: { name: owner.name, email: owner.email },
      };
    });
  }

  async adminList() {
    return this.prisma.property.findMany({
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        name: true,
        town: true,
        address: true,
        erf: true,
        size: true,
        status: true,
        fundingPercent: true,
        draftStep: true,
        owner: { select: { name: true, email: true } },
      },
    });
  }
}
