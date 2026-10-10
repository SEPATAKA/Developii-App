import { PrismaClient, EntityType, Experience } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  const adminEmail = process.env.SEED_ADMIN_EMAIL || 'admin@developify.co.za';
  const adminPassword =
    process.env.SEED_ADMIN_PASSWORD || 'Developify@Admin1';

  await prisma.adminUser.upsert({
    where: { email: adminEmail },
    create: {
      email: adminEmail,
      name: 'Developify Admin',
      role: 'admin',
      passwordHash: await argon2.hash(adminPassword),
    },
    update: {},
  });

  await prisma.systemConfig.upsert({
    where: { key: 'withdrawalFeeCents' },
    create: { key: 'withdrawalFeeCents', value: 150 },
    update: { value: 150 },
  });
  await prisma.systemConfig.upsert({
    where: { key: 'reviewBusinessDays' },
    create: { key: 'reviewBusinessDays', value: 10 },
    update: {},
  });

  const projects = [
    {
      slug: 'protea-heights',
      name: 'Protea Heights',
      town: 'Stellenbosch',
      description: 'Residential development with strong rental demand.',
      annualRateBps: 1450,
      capacityCents: 250000000n,
      fundedCents: 80000000n,
    },
    {
      slug: 'lagoon-view',
      name: 'Lagoon View',
      town: 'Cape Town',
      description: 'Coastal mixed-use development opportunity.',
      annualRateBps: 1320,
      capacityCents: 400000000n,
      fundedCents: 120000000n,
    },
    {
      slug: 'savannah-estate',
      name: 'Savannah Estate',
      town: 'Pretoria',
      description: 'Secure estate with phased unit releases.',
      annualRateBps: 1280,
      capacityCents: 180000000n,
      fundedCents: 45000000n,
    },
  ];

  for (const p of projects) {
    await prisma.project.upsert({
      where: { slug: p.slug },
      create: {
        ...p,
        status: 'open',
        publishedAt: new Date(),
        contentJson: {
          developer: 'Developify Projects',
          updates: [],
          documents: [],
          location: {
            address: `${p.town} CBD`,
            city: p.town,
            region: 'Western Cape',
            country: 'South Africa',
            mapAsset: 'assets/images/site_location_map.png',
            linkUrl: `https://maps.google.com/?q=${encodeURIComponent(p.town)}`,
            linkLabel: 'Open in Maps',
          },
          plans: [
            {
              id: `${p.slug}-plan-studio`,
              title: 'Studio layout',
              description: 'Open-plan studio with balcony access.',
              imageAsset: 'assets/images/investor_update_planning.jpg',
            },
            {
              id: `${p.slug}-plan-one-bed`,
              title: '1-bedroom layout',
              description: 'Separate bedroom and living area.',
              imageAsset: 'assets/images/site_photo_residence.png',
            },
          ],
        },
      },
      update: {
        name: p.name,
        town: p.town,
        description: p.description,
        annualRateBps: p.annualRateBps,
        contentJson: {
          developer: 'Developify Projects',
          updates: [],
          documents: [],
          location: {
            address: `${p.town} CBD`,
            city: p.town,
            region: 'Western Cape',
            country: 'South Africa',
            mapAsset: 'assets/images/site_location_map.png',
            linkUrl: `https://maps.google.com/?q=${encodeURIComponent(p.town)}`,
            linkLabel: 'Open in Maps',
          },
          plans: [
            {
              id: `${p.slug}-plan-studio`,
              title: 'Studio layout',
              description: 'Open-plan studio with balcony access.',
              imageAsset: 'assets/images/investor_update_planning.jpg',
            },
            {
              id: `${p.slug}-plan-one-bed`,
              title: '1-bedroom layout',
              description: 'Separate bedroom and living area.',
              imageAsset: 'assets/images/site_photo_residence.png',
            },
          ],
        },
      },
    });
  }

  const demoEmail = 'investor.qa@developify.co.za';
  const passwordHash = await argon2.hash('Developify@123');
  const user = await prisma.user.upsert({
    where: { email: demoEmail },
    create: {
      email: demoEmail,
      name: 'QA Investor',
      phone: '+27 82 000 0001',
      address: '14 Protea Ave, Randburg, Gauteng, 2184',
      passwordHash,
      pinHash: await argon2.hash('1234'),
      investorNumber: '1000001',
      memberships: {
        create: [
          { experience: Experience.investor },
          { experience: Experience.landowner },
        ],
      },
      preferences: { create: {} },
      securityPrefs: { create: {} },
    },
    update: { passwordHash },
  });
  if (!user.investorNumber) {
    await prisma.user.update({
      where: { id: user.id },
      data: { investorNumber: '1000001' },
    });
  }

  const entity = await prisma.investorEntity.upsert({
    where: {
      userId_entityType: {
        userId: user.id,
        entityType: EntityType.individual,
      },
    },
    create: {
      userId: user.id,
      entityType: EntityType.individual,
      verificationStatus: 'verified',
    },
    update: { verificationStatus: 'verified' },
  });

  await prisma.ledgerAccount.upsert({
    where: { entityId: entity.id },
    create: {
      type: 'userWallet',
      entityId: entity.id,
      currency: 'ZAR',
    },
    update: {},
  });

  const wallet = await prisma.ledgerAccount.findUniqueOrThrow({
    where: { entityId: entity.id },
  });
  const last = await prisma.ledgerEntry.findFirst({
    where: { accountId: wallet.id },
    orderBy: { createdAt: 'desc' },
  });
  if (!last) {
    await prisma.ledgerEntry.create({
      data: {
        accountId: wallet.id,
        amountCents: 5000000n,
        balanceAfter: 5000000n,
        memo: 'Seed wallet balance',
      },
    });
  }

  const loEmail = 'landowner.qa@developify.co.za';
  const landowner = await prisma.user.upsert({
    where: { email: loEmail },
    create: {
      email: loEmail,
      name: 'QA Landowner',
      phone: '+27 82 000 0002',
      passwordHash: await argon2.hash('Developify@123'),
      investorNumber: '1000002',
      memberships: {
        create: [{ experience: Experience.landowner }],
      },
      preferences: { create: {} },
      securityPrefs: { create: {} },
    },
    update: {},
  });
  if (!landowner.investorNumber) {
    await prisma.user.update({
      where: { id: landowner.id },
      data: { investorNumber: '1000002' },
    });
  }

  // eslint-disable-next-line no-console
  console.log('Seed complete:', {
    adminEmail,
    demoEmail,
    loEmail,
    pin: '1234',
    password: 'Developify@123',
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
