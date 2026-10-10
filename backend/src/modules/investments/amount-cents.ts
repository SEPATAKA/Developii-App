import { BadRequestException } from '@nestjs/common';

export function parseAmountCents(value: unknown): number {
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    throw new BadRequestException(
      'Amount must be an integer number of cents.',
    );
  }
  if (value < 100) {
    throw new BadRequestException('Minimum allocation is R1.00.');
  }
  if (value > 100_000_000_00) {
    throw new BadRequestException('Amount exceeds the allocation limit.');
  }
  return value;
}
