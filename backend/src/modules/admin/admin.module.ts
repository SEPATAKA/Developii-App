import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { WalletModule } from '../wallet/wallet.module';
import { LandownerModule } from '../landowner/landowner.module';
import { KycModule } from '../kyc/kyc.module';
import { InvestmentsModule } from '../investments/investments.module';

@Module({
  imports: [WalletModule, LandownerModule, KycModule, InvestmentsModule],
  controllers: [AdminController],
})
export class AdminModule {}
