import { Module } from '@nestjs/common';
import { ManualPaymentProvider, PaymentService } from './payment.service';

@Module({
  providers: [ManualPaymentProvider, PaymentService],
  exports: [PaymentService, ManualPaymentProvider],
})
export class PaymentsModule {}
