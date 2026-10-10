import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from '../common/jwt.strategy';
import { LedgerModule } from '../ledger/ledger.module';
import { RedisService } from '../common/redis.service';

@Module({
  imports: [PassportModule, JwtModule.register({}), LedgerModule],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RedisService],
  exports: [AuthService],
})
export class AuthModule {}
