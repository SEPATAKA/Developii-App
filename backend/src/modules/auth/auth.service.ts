import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { createHash, randomBytes, randomInt } from 'crypto';
import {
  ChallengePurpose,
  EntityType,
  Experience,
} from '@prisma/client';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { RedisService } from '../common/redis.service';
import { LedgerService } from '../ledger/ledger.service';
import { allocateInvestorNumber } from './investor-number';
import { FirebaseAdminService } from '../../firebase/firebase-admin.service';

export type AppUserDto = {
  id: string;
  name: string;
  email: string;
  phone: string;
  address: string;
  entity: EntityType;
  hasProfilePhoto: boolean;
  countryCode: string;
  nonResident: boolean;
  investorNumber: string | null;
  experiences: Experience[];
};

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
    private mail: MailService,
    private redis: RedisService,
    private ledger: LedgerService,
    private firebase: FirebaseAdminService,
  ) {}

  async firebaseUserSession(idToken: string) {
    let identity: Awaited<ReturnType<FirebaseAdminService['verifyIdToken']>>;
    try {
      identity = await this.firebase.verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Firebase sign-in token is invalid or expired.');
    }
    const email = identity.email?.toLowerCase().trim();
    if (!email || identity.email_verified !== true) {
      throw new UnauthorizedException('Verify your email address before signing in.');
    }
    const profile = await this.firebase.findUserSessionProfile(email);
    if (!profile) {
      throw new UnauthorizedException('No Developify user profile exists for this account.');
    }
    if (profile.locked === true) {
      throw new UnauthorizedException('This Developify account is unavailable.');
    }
    const user = {
      id: profile.id,
      name: String(profile.name ?? ''),
      email,
      phone: String(profile.phone ?? ''),
      address: String(profile.address ?? ''),
      hasProfilePhoto: profile.hasProfilePhoto === true,
      countryCode: String(profile.countryCode ?? 'ZA'),
      nonResident: profile.nonResident === true,
      investorNumber:
        typeof profile.investorNumber === 'string' ? profile.investorNumber : null,
      memberships: profile.memberships.map((membership) => ({
        experience: membership.experience as Experience,
      })),
      entities: profile.entities.map((entity) => ({
        id: String(entity.id ?? ''),
        entityType: entity.entityType as EntityType,
      })),
    };
    const primaryEntity = user.entities[0];
    if (
      !(await this.firebase.linkProfileByEmail('users', email, identity.uid))
    ) {
      throw new UnauthorizedException('This account is linked to another identity.');
    }
    return {
      user: this.toAppUser(user, primaryEntity?.entityType),
      accessToken: idToken,
    };
  }

  async firebaseAdminSession(idToken: string) {
    let identity: Awaited<ReturnType<FirebaseAdminService['verifyIdToken']>>;
    try {
      identity = await this.firebase.verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Firebase sign-in token is invalid or expired.');
    }
    const email = identity.email?.toLowerCase().trim();
    if (!email || identity.email_verified !== true) {
      throw new UnauthorizedException('Verify your email address before signing in.');
    }
    const profile = await this.firebase.findProfileByEmail('adminUsers', email);
    if (!profile) {
      throw new UnauthorizedException('This Firebase account is not an authorized admin.');
    }
    const role = profile.get('role');
    if (
      profile.get('locked') === true ||
      typeof role !== 'string' ||
      !['admin', 'ops', 'compliance'].includes(role)
    ) {
      throw new UnauthorizedException('This admin account is unavailable.');
    }
    if (
      !(await this.firebase.linkProfileByEmail(
        'adminUsers',
        email,
        identity.uid,
      ))
    ) {
      throw new UnauthorizedException('This account is linked to another identity.');
    }
    return {
      accessToken: idToken,
      admin: {
        id: profile.id,
        email,
        name: String(profile.get('name') ?? ''),
        role,
      },
    };
  }

  private async allocateUniqueInvestorNumber(
    tx: PrismaService | Prisma.TransactionClient = this.prisma,
  ) {
    const assigned = await tx.user.findMany({
      where: { investorNumber: { not: null } },
      select: { investorNumber: true },
    });
    return allocateInvestorNumber(
      new Set(
        assigned
          .map((row) => row.investorNumber)
          .filter((value): value is string => value != null),
      ),
    );
  }

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private otpCode() {
    return String(randomInt(100000, 999999));
  }

  private toAppUser(
    user: {
      id: string;
      name: string;
      email: string;
      phone: string;
      address: string;
      hasProfilePhoto: boolean;
      countryCode: string;
      nonResident: boolean;
      investorNumber: string | null;
      memberships?: { experience: Experience }[];
      entities?: { entityType: EntityType }[];
    },
    entity?: EntityType,
  ): AppUserDto {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      entity: entity ?? user.entities?.[0]?.entityType ?? EntityType.individual,
      hasProfilePhoto: user.hasProfilePhoto,
      countryCode: user.countryCode,
      nonResident: user.nonResident,
      investorNumber: user.investorNumber,
      experiences: (user.memberships ?? []).map((m) => m.experience),
    };
  }

  async issueTokens(user: {
    id: string;
    email: string;
  }, opts?: { entityId?: string; entityType?: string }) {
    const accessToken = await this.jwt.signAsync(
      {
        sub: user.id,
        email: user.email,
        typ: 'user',
        entityId: opts?.entityId,
        entityType: opts?.entityType,
      },
      {
        secret: this.config.getOrThrow('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get('JWT_ACCESS_TTL', '15m'),
      },
    );
    const refreshToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email, typ: 'refresh' },
      {
        secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get('JWT_REFRESH_TTL', '30d'),
      },
    );
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: this.hashToken(refreshToken),
        expiresAt,
      },
    });
    return { accessToken, refreshToken };
  }

  async signIn(email: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
      include: { memberships: true, entities: true },
    });
    if (!user || user.locked) {
      throw new UnauthorizedException({
        kind: 'unauthenticated',
        message: 'Invalid email or password.',
      });
    }
    const ok = await argon2.verify(user.passwordHash, password);
    if (!ok) {
      throw new UnauthorizedException({
        kind: 'unauthenticated',
        message: 'Invalid email or password.',
      });
    }
    const primaryEntity = user.entities[0];
    const tokens = await this.issueTokens(user, {
      entityId: primaryEntity?.id,
      entityType: primaryEntity?.entityType,
    });
    return { user: this.toAppUser(user, primaryEntity?.entityType), ...tokens };
  }

  async socialSignIn(_provider: string) {
    throw new BadRequestException({
      kind: 'configuration',
      message: 'Social sign-in is not configured yet.',
    });
  }

  async registerLandowner(input: {
    name: string;
    email: string;
    phone: string;
    password?: string;
    countryCode?: string;
    entity?: EntityType;
    idToken?: string;
  }) {
    const email = input.email.toLowerCase().trim();
    const identity = input.idToken
      ? await this.firebase.verifyIdToken(input.idToken)
      : null;
    if (
      identity &&
      identity.email?.toLowerCase().trim() !== email
    ) {
      throw new UnauthorizedException('Firebase account email does not match.');
    }
    if (!identity && !input.password) {
      throw new BadRequestException('A password is required for legacy account creation.');
    }
    if (identity && (await this.firebase.findProfileByEmail('users', email))) {
      throw new ConflictException('A Developify profile already exists for this email.');
    }
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException({
        kind: 'conflict',
        message: 'An account with this email already exists.',
        fieldErrors: { email: 'Email is already registered.' },
      });
    }
    const passwordHash = await argon2.hash(
      identity ? randomBytes(32).toString('hex') : input.password!,
    );
    const user = await this.prisma.$transaction(async (tx) => {
      const investorNumber = await this.allocateUniqueInvestorNumber(tx);
      return tx.user.create({
        data: {
          email,
          name: input.name.trim(),
          phone: input.phone.trim(),
          countryCode: input.countryCode ?? 'ZA',
          passwordHash,
          investorNumber,
          memberships: { create: [{ experience: Experience.landowner }] },
          ...(input.entity
            ? { entities: { create: [{ entityType: input.entity }] } }
            : {}),
        preferences: {
          create: {
            channels: {
              'Push Notification': true,
              Email: true,
              SMS: true,
            },
            topics: {
              'Investment Confirmations': true,
              'New projects matching my interest': true,
              'Distribution payments': true,
              'Wallet activity': true,
              'Marketing & tips': true,
            },
          },
        },
        securityPrefs: { create: {} },
        },
        include: { memberships: true, entities: true },
      });
    });
    if (
      identity &&
      !(await this.firebase.saveRegisteredUserProfile(user, identity.uid))
    ) {
      throw new ConflictException('A Developify profile already exists for this email.');
    }
    const tokens = identity
      ? { accessToken: input.idToken }
      : await this.issueTokens(user);
    return { user: this.toAppUser(user), ...tokens };
  }

  async beginInvestorRegistration(input: {
    name: string;
    email: string;
    phone: string;
    password?: string;
    firebaseAuth?: boolean;
    entity: EntityType;
    nonResident?: boolean;
    countryCode?: string;
  }) {
    const email = input.email.toLowerCase().trim();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException({
        kind: 'conflict',
        message: 'An account with this email already exists.',
        fieldErrors: { email: 'Email is already registered.' },
      });
    }
    if (!input.firebaseAuth && !input.password) {
      throw new BadRequestException('A password is required for legacy account creation.');
    }
    const code = input.firebaseAuth ? null : this.otpCode();
    const passwordHash =
      input.firebaseAuth || !input.password
        ? undefined
        : await argon2.hash(input.password);
    const challenge = await this.prisma.authChallenge.create({
      data: {
        email,
        purpose: ChallengePurpose.investorRegistration,
        codeHash: this.hashToken(code ?? randomBytes(32).toString('hex')),
        expiresAt: new Date(
          Date.now() +
            Number(this.config.get('OTP_TTL_MINUTES', 15)) * 60 * 1000,
        ),
        payload: {
          name: input.name,
          phone: input.phone,
          ...(passwordHash ? { passwordHash } : {}),
          firebaseAuth: input.firebaseAuth ?? false,
          entity: input.entity,
          nonResident: input.nonResident ?? false,
          countryCode: input.countryCode ?? 'ZA',
        },
      },
    });
    if (code) await this.mail.sendOtp(email, code, 'registration');
    return { challengeId: challenge.id };
  }

  async verifyInvestorRegistration(challengeId: string, code: string) {
    const challenge = await this.prisma.authChallenge.findUnique({
      where: { id: challengeId },
    });
    if (
      !challenge ||
      challenge.purpose !== ChallengePurpose.investorRegistration ||
      challenge.expiresAt < new Date()
    ) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Verification code expired or invalid.',
      });
    }
    if (challenge.attempts >= 5) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Too many attempts. Request a new code.',
      });
    }
    await this.prisma.authChallenge.update({
      where: { id: challengeId },
      data: { attempts: { increment: 1 } },
    });
    if (challenge.codeHash !== this.hashToken(code)) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Incorrect verification code.',
        fieldErrors: { code: 'Incorrect code.' },
      });
    }
    await this.prisma.authChallenge.update({
      where: { id: challengeId },
      data: { verified: true },
    });
    return { ok: true };
  }

  async completeInvestorRegistration(challengeId: string, idToken?: string) {
    const challenge = await this.prisma.authChallenge.findUnique({
      where: { id: challengeId },
    });
    if (!challenge || challenge.expiresAt < new Date()) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Registration challenge is not verified.',
      });
    }
    const payload = challenge.payload as {
      name: string;
      phone: string;
      passwordHash?: string;
      firebaseAuth?: boolean;
      entity: EntityType;
      nonResident: boolean;
      countryCode: string;
    };
    if (payload.firebaseAuth && !idToken) {
      throw new UnauthorizedException(
        'Complete this registration using Firebase Authentication.',
      );
    }
    const identity = idToken
      ? await this.firebase.verifyIdToken(idToken)
      : null;
    if (
      identity &&
      identity.email?.toLowerCase().trim() !== challenge.email.toLowerCase().trim()
    ) {
      throw new UnauthorizedException('Firebase account email does not match.');
    }
    if (payload.firebaseAuth && identity?.email_verified !== true) {
      throw new UnauthorizedException(
        'Verify your email using the Firebase link before continuing.',
      );
    }
    if (!payload.firebaseAuth && !challenge.verified) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Registration challenge is not verified.',
      });
    }
    const user = await this.prisma.$transaction(async (tx) => {
      const investorNumber = await this.allocateUniqueInvestorNumber(tx);
      const created = await tx.user.create({
        data: {
          email: challenge.email,
          name: payload.name,
          phone: payload.phone,
          passwordHash:
            identity || !payload.passwordHash
              ? await argon2.hash(randomBytes(32).toString('hex'))
              : payload.passwordHash,
          countryCode: payload.countryCode,
          nonResident: payload.nonResident,
          investorNumber,
          memberships: {
            create: [
              { experience: Experience.investor },
              { experience: Experience.landowner },
            ],
          },
          preferences: { create: {} },
          securityPrefs: { create: {} },
        },
      });
      const entity = await tx.investorEntity.create({
        data: {
          userId: created.id,
          entityType: payload.entity,
          nonResident: payload.nonResident,
        },
      });
      await tx.authChallenge.delete({ where: { id: challengeId } });
      return { created, entity };
    });
    await this.ledger.ensureWallet(user.entity.id);
    const full = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.created.id },
      include: { memberships: true, entities: true },
    });
    if (identity) {
      if (!(await this.firebase.saveRegisteredUserProfile(full, identity.uid))) {
        throw new ConflictException(
          'A Developify profile already exists for this email.',
        );
      }
    }
    const tokens = await this.issueTokens(full, {
      entityId: user.entity.id,
      entityType: user.entity.entityType,
    });
    return {
      user: this.toAppUser(full, user.entity.entityType),
      ...(identity ? { accessToken: idToken } : tokens),
    };
  }

  async cancelInvestorRegistration(challengeId: string) {
    await this.prisma.authChallenge.deleteMany({ where: { id: challengeId } });
  }

  async requestRecovery(email: string) {
    const normalized = email.toLowerCase().trim();
    const user = await this.prisma.user.findUnique({
      where: { email: normalized },
    });
    // Always succeed to avoid email enumeration
    if (!user) return { ok: true };
    const code = this.otpCode();
    await this.prisma.authChallenge.create({
      data: {
        email: normalized,
        userId: user.id,
        purpose: ChallengePurpose.passwordRecovery,
        codeHash: this.hashToken(code),
        expiresAt: new Date(
          Date.now() +
            Number(this.config.get('OTP_TTL_MINUTES', 15)) * 60 * 1000,
        ),
      },
    });
    await this.mail.sendOtp(normalized, code, 'password recovery');
    return { ok: true };
  }

  async verifyRecovery(email: string, code: string) {
    const challenge = await this.prisma.authChallenge.findFirst({
      where: {
        email: email.toLowerCase().trim(),
        purpose: ChallengePurpose.passwordRecovery,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Recovery code expired or invalid.',
      });
    }
    if (challenge.codeHash !== this.hashToken(code)) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Incorrect recovery code.',
      });
    }
    await this.prisma.authChallenge.update({
      where: { id: challenge.id },
      data: { verified: true },
    });
    await this.redis.setex(`recovery:${challenge.id}`, 900, '1');
    return { challengeId: challenge.id };
  }

  async resetPassword(challengeId: string, password: string) {
    const allowed = await this.redis.get(`recovery:${challengeId}`);
    const challenge = await this.prisma.authChallenge.findUnique({
      where: { id: challengeId },
    });
    if (!allowed || !challenge?.verified || !challenge.userId) {
      throw new BadRequestException({
        kind: 'validation',
        message: 'Recovery session is invalid.',
      });
    }
    const passwordHash = await argon2.hash(password);
    await this.prisma.user.update({
      where: { id: challenge.userId },
      data: { passwordHash },
    });
    await this.prisma.authChallenge.delete({ where: { id: challengeId } });
    await this.redis.del(`recovery:${challengeId}`);
    await this.prisma.refreshToken.updateMany({
      where: { userId: challenge.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string; email: string; typ: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token.');
    }
    if (payload.typ !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token.');
    }
    const hash = this.hashToken(refreshToken);
    const stored = await this.prisma.refreshToken.findFirst({
      where: {
        userId: payload.sub,
        tokenHash: hash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!stored) {
      throw new UnauthorizedException('Refresh token revoked or expired.');
    }
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: payload.sub },
      include: { memberships: true, entities: true },
    });
    const entity = user.entities[0];
    const tokens = await this.issueTokens(user, {
      entityId: entity?.id,
      entityType: entity?.entityType,
    });
    return { user: this.toAppUser(user, entity?.entityType), ...tokens };
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      await this.prisma.refreshToken.updateMany({
        where: { userId, tokenHash: this.hashToken(refreshToken) },
        data: { revokedAt: new Date() },
      });
    } else {
      await this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { ok: true };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { memberships: true, entities: true },
    });
    return this.toAppUser(user);
  }

  async adminSignIn(email: string, password: string) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
    if (!admin || admin.locked) {
      throw new UnauthorizedException('Invalid admin credentials.');
    }
    const ok = await argon2.verify(admin.passwordHash, password);
    if (!ok) throw new UnauthorizedException('Invalid admin credentials.');
    const accessToken = await this.jwt.signAsync(
      {
        sub: admin.id,
        email: admin.email,
        typ: 'admin',
        role: admin.role,
      },
      {
        secret: this.config.getOrThrow('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get('JWT_ACCESS_TTL', '15m'),
      },
    );
    return {
      accessToken,
      admin: {
        id: admin.id,
        email: admin.email,
        name: admin.name,
        role: admin.role,
      },
    };
  }
}
