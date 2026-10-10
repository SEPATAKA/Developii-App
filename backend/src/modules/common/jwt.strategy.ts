import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
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
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
  }

  validate(payload: JwtPayload): AuthUser {
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
