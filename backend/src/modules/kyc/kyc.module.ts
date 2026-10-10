import { Module } from '@nestjs/common';
import { KycService, ManualKycProvider } from './kyc.service';
import { AdminKycController, KycController } from './kyc.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [UsersModule],
  providers: [KycService, ManualKycProvider],
  controllers: [KycController, AdminKycController],
  exports: [KycService],
})
export class KycModule {}
