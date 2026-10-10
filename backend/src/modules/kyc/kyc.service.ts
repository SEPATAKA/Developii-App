import { Injectable, NotFoundException } from '@nestjs/common';
import { EntityType, VerificationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';

/** Manual admin KYC provider. Swap for Smile ID / Onfido later. */
@Injectable()
export class ManualKycProvider {
  readonly name = 'manual';
}

@Injectable()
export class KycService {
  constructor(
    private prisma: PrismaService,
    private users: UsersService,
    private provider: ManualKycProvider,
  ) {}

  private mapDraft(draft: {
    id: string;
    fields: unknown;
    status: VerificationStatus;
    reviewNote: string | null;
    submittedAt: Date | null;
    reviewedAt: Date | null;
    entity: { entityType: EntityType; id: string };
    documents: {
      id: string;
      key: string;
      name: string;
      mimeType: string;
      sizeBytes: number;
      storageKey: string;
    }[];
    members: {
      id: string;
      role: string;
      fields: unknown;
      allocation: number;
      documents: {
        id: string;
        key: string;
        name: string;
        mimeType: string;
        sizeBytes: number;
        storageKey: string;
      }[];
    }[];
    invites: {
      id: string;
      email: string;
      role: string;
      accepted: boolean;
    }[];
  }) {
    return {
      id: draft.id,
      entityId: draft.entity.id,
      entity: draft.entity.entityType,
      fields: draft.fields,
      status: draft.status,
      reviewNote: draft.reviewNote,
      submittedAt: draft.submittedAt?.toISOString() ?? null,
      reviewedAt: draft.reviewedAt?.toISOString() ?? null,
      provider: this.provider.name,
      documents: draft.documents,
      members: draft.members,
      invites: draft.invites,
    };
  }

  async load(userId: string, entityType: EntityType) {
    const entity = await this.users.resolveEntity(userId, entityType);
    let draft = await this.prisma.kycDraft.findUnique({
      where: { entityId: entity.id },
      include: {
        entity: true,
        documents: true,
        members: { include: { documents: true } },
        invites: true,
      },
    });
    if (!draft) {
      draft = await this.prisma.kycDraft.create({
        data: { entityId: entity.id, fields: {}, status: VerificationStatus.incomplete },
        include: {
          entity: true,
          documents: true,
          members: { include: { documents: true } },
          invites: true,
        },
      });
    }
    return this.mapDraft(draft);
  }

  async save(userId: string, entityType: EntityType, fields: Record<string, unknown>) {
    const entity = await this.users.resolveEntity(userId, entityType);
    await this.prisma.kycDraft.upsert({
      where: { entityId: entity.id },
      create: {
        entityId: entity.id,
        fields: fields as object,
        status: VerificationStatus.incomplete,
      },
      update: {
        fields: fields as object,
        status: VerificationStatus.incomplete,
        reviewNote: null,
      },
    });
    await this.prisma.investorEntity.update({
      where: { id: entity.id },
      data: { verificationStatus: VerificationStatus.incomplete },
    });
    return this.load(userId, entityType);
  }

  async upload(
    userId: string,
    entityType: EntityType,
    data: {
      key: string;
      name: string;
      mimeType: string;
      sizeBytes: number;
      storageKey: string;
      memberId?: string;
    },
  ) {
    const entity = await this.users.resolveEntity(userId, entityType);
    const draft = await this.prisma.kycDraft.upsert({
      where: { entityId: entity.id },
      create: { entityId: entity.id },
      update: {},
    });
    await this.prisma.document.create({
      data: {
        draftId: draft.id,
        memberId: data.memberId,
        key: data.key,
        name: data.name,
        mimeType: data.mimeType,
        sizeBytes: data.sizeBytes,
        storageKey: data.storageKey,
      },
    });
    return this.load(userId, entityType);
  }

  async saveMember(
    userId: string,
    entityType: EntityType,
    member: { id?: string; role: string; fields: object; allocation?: number },
  ) {
    const draft = await this.load(userId, entityType);
    if (member.id) {
      await this.prisma.kycMember.update({
        where: { id: member.id },
        data: {
          role: member.role,
          fields: member.fields,
          allocation: member.allocation ?? 0,
        },
      });
    } else {
      await this.prisma.kycMember.create({
        data: {
          draftId: draft.id,
          role: member.role,
          fields: member.fields,
          allocation: member.allocation ?? 0,
        },
      });
    }
    return this.load(userId, entityType);
  }

  async invite(
    userId: string,
    entityType: EntityType,
    invite: { email: string; role: string },
  ) {
    const draft = await this.load(userId, entityType);
    await this.prisma.kycInvite.create({
      data: {
        draftId: draft.id,
        email: invite.email.toLowerCase(),
        role: invite.role,
      },
    });
    return this.load(userId, entityType);
  }

  async submit(userId: string, entityType: EntityType) {
    const entity = await this.users.resolveEntity(userId, entityType);
    const draft = await this.prisma.kycDraft.update({
      where: { entityId: entity.id },
      data: {
        status: VerificationStatus.pending,
        submittedAt: new Date(),
      },
      include: {
        entity: true,
        documents: true,
        members: { include: { documents: true } },
        invites: true,
      },
    });
    await this.prisma.investorEntity.update({
      where: { id: entity.id },
      data: { verificationStatus: VerificationStatus.pending },
    });
    return this.mapDraft(draft);
  }

  async adminDecide(
    adminId: string,
    draftId: string,
    decision: 'verified' | 'correctionRequired' | 'incomplete',
    note?: string,
  ) {
    const draft = await this.prisma.kycDraft.findUnique({
      where: { id: draftId },
    });
    if (!draft) throw new NotFoundException('KYC draft not found.');
    const status =
      decision === 'verified'
        ? VerificationStatus.verified
        : decision === 'correctionRequired'
          ? VerificationStatus.correctionRequired
          : VerificationStatus.incomplete;
    const updated = await this.prisma.kycDraft.update({
      where: { id: draftId },
      data: {
        status,
        reviewNote: note,
        reviewedAt: new Date(),
        reviewedBy: adminId,
      },
      include: {
        entity: true,
        documents: true,
        members: { include: { documents: true } },
        invites: true,
      },
    });
    await this.prisma.investorEntity.update({
      where: { id: draft.entityId },
      data: { verificationStatus: status },
    });
    await this.prisma.auditLog.create({
      data: {
        actorAdminId: adminId,
        action: `kyc.${decision}`,
        resource: 'kycDraft',
        resourceId: draftId,
        metadata: { note },
      },
    });
    return this.mapDraft(updated);
  }

  async adminQueue() {
    return this.prisma.kycDraft.findMany({
      where: { status: VerificationStatus.pending },
      include: {
        entity: { include: { user: true } },
        documents: true,
      },
      orderBy: { submittedAt: 'asc' },
    });
  }
}
