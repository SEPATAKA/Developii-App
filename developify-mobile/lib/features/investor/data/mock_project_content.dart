import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';

InvestorProjectContent createMockProjectContent(
  String projectId,
) => InvestorProjectContent(
  documents: [
    if (projectId == 'marula-heights')
      InvestorProjectDocument(
        id: '$projectId-cipc-registration',
        name: 'CIPC_CoR14_3_Marula',
      ),
  ],
  description:
      'A 42-unit residential development across 4 floors on a 0.5-acre site. Each unit averages 78 sqm with sea-facing balconies, smart locks, and shared rooftop amenities including a pool, gym, and co-working lounge.',
  facts: const {
    'Type': 'Residential',
    'Floors': '4',
    'Units': '42',
    'Avg Unit Size': '78 sqm',
    'Parking': '60 Spaces',
    'Title': 'C of O Verified',
    'Insurance': 'Allianz Construction',
  },
  location: InvestorProjectLocation(
    address: projectId == 'marula-heights'
        ? '14 Protea Avenue, Sea Point'
        : 'Lagoon Drive, Victoriaibault',
    city: projectId == 'marula-heights' ? 'Cape Town' : 'Stellenbosch',
    region: 'Western Cape',
    country: 'South Africa',
    mapAsset: AppAssets.siteMap,
    linkUrl: projectId == 'marula-heights'
        ? 'https://maps.google.com/?q=-33.915,-18.387'
        : 'https://maps.google.com/?q=-33.932,-18.860',
    linkLabel: 'Open in Maps',
  ),
  plans: [
    InvestorProjectPlan(
      id: '$projectId-plan-studio',
      title: 'Studio layout',
      description: 'Open-plan studio with balcony access and compact kitchen.',
      imageAsset: AppAssets.investorUpdatePlanning,
    ),
    InvestorProjectPlan(
      id: '$projectId-plan-one-bed',
      title: '1-bedroom layout',
      description: 'Separate bedroom, living area, and sea-facing balcony.',
      imageAsset: AppAssets.sitePhotoResidence,
    ),
    InvestorProjectPlan(
      id: '$projectId-plan-two-bed',
      title: '2-bedroom layout',
      description: 'Two bedrooms with shared living space and dual balconies.',
      imageAsset: AppAssets.sitePhotoVilla,
    ),
  ],
  developer: InvestorDeveloperProfile(
    name: 'Palm & Brick Capital',
    initials: 'PB',
    description:
        'Palm & Brick Capital has developed 24 properties across Nigeria and Ghana since 2014, with a focus on mid-rise residential and mixed-use schemes in fast-growing coastal cities',
    completedProjects: 24,
    returnBasisPoints: 1360,
    onTimePercent: 94,
    ratingTenths: 48,
    pastProjectIds: const [
      'marula-heights',
      'lissana-villa',
      'saffron-hospitality',
    ],
  ),
  updates: [
    for (final (id, image) in const [
      ('planning', AppAssets.investorUpdatePlanning),
      ('review', AppAssets.investorUpdateReview),
      ('site-visit', AppAssets.investorUpdateSiteVisit),
    ])
      InvestorProjectUpdate(
        id: id,
        imageAsset: image,
        title: 'Foundation Poured',
        message:
            'All raft slabs poured ahead of schedule.\nInspection passed on June 6, 2026: 12 45pm',
        publishedAt: DateTime.utc(2026, 6, 7),
        events: [
          for (final day in [8, 8, 7, 7])
            InvestorProjectEvent(
              title: 'Foundation Poured',
              message:
                  'All raft slabs poured ahead of schedule.\nInspection passed on June 6, 2026: 12 45pm',
              occurredAt: DateTime.utc(2026, 6, day, 12, 45),
            ),
        ],
      ),
  ],
);
