import { randomInt } from 'crypto';

/** Inclusive 7-digit range: 1000000–9999999. */
export function drawInvestorNumber(
  draw: () => number = () => randomInt(1_000_000, 10_000_000),
): string {
  const value = draw();
  if (!Number.isInteger(value) || value < 1_000_000 || value > 9_999_999) {
    throw new Error('Investor number must be a 7-digit integer.');
  }
  return String(value);
}

export function allocateInvestorNumber(
  taken: ReadonlySet<string>,
  draw: () => number = () => randomInt(1_000_000, 10_000_000),
): string {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const candidate = drawInvestorNumber(draw);
    if (!taken.has(candidate)) return candidate;
  }
  throw new Error('Could not allocate a unique investor number.');
}
