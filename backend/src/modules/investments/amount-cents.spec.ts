import { BadRequestException } from '@nestjs/common';
import { parseAmountCents } from './amount-cents';

describe('parseAmountCents', () => {
  it('accepts a whole number of cents', () => {
    expect(parseAmountCents(250000)).toBe(250000);
  });

  it('rejects fractional and non-numeric amounts', () => {
    expect(() => parseAmountCents(10.5)).toThrow(BadRequestException);
    expect(() => parseAmountCents('250000')).toThrow(BadRequestException);
  });

  it('rejects amounts below one rand', () => {
    expect(() => parseAmountCents(99)).toThrow('Minimum allocation');
  });
});
