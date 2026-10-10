import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { memberships: true, entities: true },
    });
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      entity: user.entities[0]?.entityType ?? 'individual',
      hasProfilePhoto: user.hasProfilePhoto,
      countryCode: user.countryCode,
      nonResident: user.nonResident,
      investorNumber: user.investorNumber,
      experiences: user.memberships.map((m) => m.experience),
    };
  }

  async updateProfile(
    userId: string,
    data: Partial<{
      name: string;
      email: string;
      phone: string;
      address: string;
      countryCode: string;
      hasProfilePhoto: boolean;
      nonResident: boolean;
    }>,
  ) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data,
      include: { memberships: true, entities: true },
    });
    return this.getProfile(user.id);
  }

  async getPreferences(userId: string) {
    const prefs = await this.prisma.userPreferences.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
    return {
      channels: prefs.channels,
      topics: prefs.topics,
      language: prefs.language,
    };
  }

  async updatePreferences(
    userId: string,
    data: {
      channels?: Record<string, boolean>;
      topics?: Record<string, boolean>;
      language?: string;
    },
  ) {
    const prefs = await this.prisma.userPreferences.upsert({
      where: { userId },
      create: {
        userId,
        channels: data.channels ?? {},
        topics: data.topics ?? {},
        language: data.language ?? 'English (UK)',
      },
      update: {
        channels: data.channels,
        topics: data.topics,
        language: data.language,
      },
    });
    return {
      channels: prefs.channels,
      topics: prefs.topics,
      language: prefs.language,
    };
  }

  async getPayout(userId: string) {
    return this.prisma.payoutAccount.findUnique({ where: { userId } });
  }

  async updatePayout(
    userId: string,
    data: {
      bank: string;
      number: string;
      type: string;
      branchCode: string;
      holder: string;
      proofKey?: string;
    },
  ) {
    return this.prisma.payoutAccount.upsert({
      where: { userId },
      create: { userId, ...data },
      update: data,
    });
  }

  async getSecurity(userId: string) {
    return this.prisma.securityPreferences.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
  }

  async updateSecurity(
    userId: string,
    action: string,
    pin?: string,
    password?: string,
    currentPassword?: string,
  ) {
    if (action === 'setPin') {
      if (!pin || pin.length < 4) {
        throw new BadRequestException('PIN must be at least 4 digits.');
      }
      await this.prisma.user.update({
        where: { id: userId },
        data: { pinHash: await argon2.hash(pin) },
      });
      return { ok: true };
    }
    if (action === 'changePassword') {
      const user = await this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
      });
      if (!password || !currentPassword) {
        throw new BadRequestException('Current and new password required.');
      }
      const ok = await argon2.verify(user.passwordHash, currentPassword);
      if (!ok) throw new BadRequestException('Current password is incorrect.');
      await this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash: await argon2.hash(password) },
      });
      return { ok: true };
    }
    if (action === 'saveBiometrics' || action === 'saveTwoFactor') {
      return this.getSecurity(userId);
    }
    throw new BadRequestException(`Unknown security action: ${action}`);
  }

  async verifyPin(userId: string, pin: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (!user.pinHash) {
      throw new BadRequestException('Transaction PIN is not set.');
    }
    const ok = await argon2.verify(user.pinHash, pin);
    if (!ok) throw new BadRequestException('Incorrect PIN.');
    return true;
  }

  async resolveEntity(userId: string, entityType?: string) {
    const entity = await this.prisma.investorEntity.findFirst({
      where: {
        userId,
        ...(entityType ? { entityType: entityType as never } : {}),
      },
      orderBy: { createdAt: 'asc' },
    });
    if (!entity) {
      throw new NotFoundException('Investor entity not found.');
    }
    return entity;
  }
}
