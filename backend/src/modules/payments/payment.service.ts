import { Injectable } from '@nestjs/common';

/** Phase-1 manual EFT payment provider. Swap for Paystack later. */
export interface PaymentProvider {
  readonly name: string;
  initiateDeposit(input: {
    amountCents: bigint;
    reference: string;
    entityId: string;
  }): Promise<{
    status: 'pending';
    instructions: Record<string, string>;
  }>;
  initiateWithdrawal(input: {
    amountCents: bigint;
    reference: string;
    methodId: string;
  }): Promise<{ status: 'pending' }>;
}

@Injectable()
export class ManualPaymentProvider implements PaymentProvider {
  readonly name = 'manual';

  async initiateDeposit(input: {
    amountCents: bigint;
    reference: string;
    entityId: string;
  }) {
    return {
      status: 'pending' as const,
      instructions: {
        bank: 'Developify Holdings',
        accountNumber: '6284190219',
        branchCode: '250655',
        reference: input.reference,
        amountCents: String(input.amountCents),
        note: 'Upload proof or wait for admin confirmation.',
      },
    };
  }

  async initiateWithdrawal(_input: {
    amountCents: bigint;
    reference: string;
    methodId: string;
  }) {
    return { status: 'pending' as const };
  }
}

@Injectable()
export class PaymentService {
  constructor(private provider: ManualPaymentProvider) {}

  get active(): PaymentProvider {
    return this.provider;
  }
}
