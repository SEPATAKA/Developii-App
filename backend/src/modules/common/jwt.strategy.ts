import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import type { Request } from 'express';
import { FirebaseAdminService } from '../../firebase/firebase-admin.service';
import { AuthUser } from './auth.decorators';

type JwtPayload = {
  sub: string;
  email: string;
  typ: 'user' | 'admin';
  role?: string;
  entityId?: string;
  entityType?: string;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly config: ConfigService,
    private readonly jwt: JwtService,
    private readonly firebase: FirebaseAdminService,
  ) {
    super();
  }

  async validate(request: Request): Promise<AuthUser> {
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authentication required.');
    }
    const token = authorization.slice('Bearer '.length);

    let identity: Awaited<ReturnType<FirebaseAdminService['verifyIdToken']>>;
    try {
      identity = await this.firebase.verifyIdToken(token);
    } catch {
      return this.validateLegacyToken(token);
    }
    const email = identity.email?.toLowerCase().trim();
    if (!email || identity.email_verified !== true) {
      throw new UnauthorizedException('Verified Firebase email required.');
    }
    const userProfile = await this.firebase.findProfileByEmail('users', email);
    if (userProfile?.get('firebaseUid') === identity.uid) {
      if (userProfile.get('locked') === true) {
        throw new UnauthorizedException('This account is locked.');
      }
      return {
        id: userProfile.id,
        email,
        type: 'user',
      };
    }

    const adminProfile = await this.firebase.findProfileByEmail(
      'adminUsers',
      email,
    );
    const role = adminProfile?.get('role');
    if (
      adminProfile?.get('firebaseUid') === identity.uid &&
      adminProfile.get('locked') !== true &&
      typeof role === 'string' &&
      ['admin', 'ops', 'compliance'].includes(role)
    ) {
      return {
        id: adminProfile.id,
        email,
        type: 'admin',
        role,
      };
    }
    throw new UnauthorizedException(
      'No active Developify profile is linked to this identity.',
    );
  }

  private async validateLegacyToken(token: string): Promise<AuthUser> {
    let payload: JwtPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtPayload>(token, {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired sign-in token.');
    }
    if (!payload?.sub || !payload?.email || !payload?.typ) {
      throw new UnauthorizedException('Invalid token.');
    }
    return {
      id: payload.sub,
      email: payload.email,
      type: payload.typ,
      role: payload.role,
      entityId: payload.entityId,
      entityType: payload.entityType,
    };
  }
}
