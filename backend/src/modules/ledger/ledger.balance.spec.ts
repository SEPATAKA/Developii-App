import { InternalServerErrorException } from '@nestjs/common';
import { assertBalancedLedger } from './ledger.service';

describe('ledger batches', () => {
  it('accepts a batch that sums to zero', () => {
    expect(() =>
      assertBalancedLedger([
        { amountCents: -150n },
        { amountCents: 100n },
        { amountCents: 50n },
      ]),
    ).not.toThrow();
  });

  it('refuses an unbalanced batch', () => {
    expect(() =>
      assertBalancedLedger([{ amountCents: 5000000n }]),
    ).toThrow(InternalServerErrorException);
  });
});
