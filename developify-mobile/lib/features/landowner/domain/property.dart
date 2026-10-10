enum PropertyStatus { draft, underReview, offerReady, live, paused }

extension PropertyStatusLabel on PropertyStatus {
  String get label => switch (this) {
    PropertyStatus.draft => 'Draft',
    PropertyStatus.underReview => 'Under review',
    PropertyStatus.offerReady => 'Offer ready',
    PropertyStatus.live => 'Live project',
    PropertyStatus.paused => 'Paused',
  };
}

final class Property {
  const Property({
    required this.id,
    required this.name,
    required this.town,
    required this.status,
    this.size = '820 m²',
    this.fundingPercent = 65,
    this.draftStep = 6,
    this.erf = '4412',
    this.address = 'Malibongwe Drive, off Republic Rd',
  });
  final String id;
  final String name;
  final String town;
  final PropertyStatus status;
  final String size;
  final int fundingPercent;
  final int draftStep;
  final String erf;
  final String address;
}

final class LandownerOverview {
  const LandownerOverview({
    required this.properties,
    this.earnedCents = 48000001,
    this.propertyCount = 5,
    this.approvedCount = 2,
    this.nextPayoutCents = 6000000,
  });
  final List<Property> properties;
  final int earnedCents;
  final int propertyCount;
  final int approvedCount;
  final int nextPayoutCents;
}

final class Payout {
  const Payout({
    required this.id,
    required this.propertyName,
    required this.amountCents,
    required this.period,
    required this.date,
  });
  final String id;
  final String propertyName;
  final int amountCents;
  final String period;
  final String date;
}

final class EarningsSummary {
  const EarningsSummary({
    required this.payouts,
    this.totalCents = 48000001,
    this.nextPayoutCents = 6000000,
  });
  final List<Payout> payouts;
  final int totalCents;
  final int nextPayoutCents;
}
