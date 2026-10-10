import { Module } from '@nestjs/common';
import { InvestmentsService } from './investments.service';
import { InvestmentsController } from './investments.controller';
import { LedgerModule } from '../ledger/ledger.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [LedgerModule, UsersModule],
  providers: [InvestmentsService],
  controllers: [InvestmentsController],
  exports: [InvestmentsService],
})
export class InvestmentsModule {}
