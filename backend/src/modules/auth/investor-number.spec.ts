import { allocateInvestorNumber, drawInvestorNumber } from './investor-number';

describe('investor numbers', () => {
  it('draws a 7-digit number', () => {
    expect(drawInvestorNumber(() => 1_000_000)).toBe('1000000');
    expect(drawInvestorNumber(() => 9_999_999)).toBe('9999999');
  });

  it('rejects values outside the 7-digit range', () => {
    expect(() => drawInvestorNumber(() => 999_999)).toThrow(
      '7-digit integer',
    );
  });

  it('skips numbers that are already assigned', () => {
    const taken = new Set(['1000000', '1000001']);
    const draws = [1_000_000, 1_000_001, 1_000_002];
    expect(
      allocateInvestorNumber(taken, () => draws.shift() ?? 0),
    ).toBe('1000002');
  });
});
