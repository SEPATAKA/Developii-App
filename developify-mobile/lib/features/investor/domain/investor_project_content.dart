final class InvestorProjectUpdate {
  InvestorProjectUpdate({
    required this.id,
    required this.title,
    required this.message,
    required this.imageAsset,
    required this.publishedAt,
    required List<InvestorProjectEvent> events,
  }) : events = List.unmodifiable(events);
  final String id;
  final String title;
  final String message;
  final String imageAsset;
  final DateTime publishedAt;
  final List<InvestorProjectEvent> events;
}

final class InvestorProjectEvent {
  const InvestorProjectEvent({
    required this.title,
    required this.message,
    required this.occurredAt,
  });
  final String title;
  final String message;
  final DateTime occurredAt;
}

final class InvestorDeveloperProfile {
  InvestorDeveloperProfile({
    required this.name,
    required this.initials,
    required this.description,
    required this.completedProjects,
    required this.returnBasisPoints,
    required this.onTimePercent,
    required this.ratingTenths,
    required List<String> pastProjectIds,
  }) : pastProjectIds = List.unmodifiable(pastProjectIds);
  final String name;
  final String initials;
  final String description;
  final int completedProjects;
  final int returnBasisPoints;
  final int onTimePercent;
  final int ratingTenths;
  final List<String> pastProjectIds;
}

final class InvestorProjectLocation {
  const InvestorProjectLocation({
    required this.address,
    required this.city,
    required this.region,
    required this.country,
    required this.mapAsset,
    required this.linkUrl,
    required this.linkLabel,
  });
  final String address;
  final String city;
  final String region;
  final String country;
  final String mapAsset;
  final String linkUrl;
  final String linkLabel;
}

final class InvestorProjectPlan {
  const InvestorProjectPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
  });
  final String id;
  final String title;
  final String description;
  final String imageAsset;
}

final class InvestorProjectContent {
  InvestorProjectContent({
    required this.description,
    required Map<String, String> facts,
    required this.developer,
    required List<InvestorProjectUpdate> updates,
    List<InvestorProjectDocument> documents = const [],
    this.location,
    List<InvestorProjectPlan> plans = const [],
  }) : facts = Map.unmodifiable(facts),
       documents = List.unmodifiable(documents),
       updates = List.unmodifiable(updates),
       plans = List.unmodifiable(plans);
  final String description;
  final Map<String, String> facts;
  final InvestorDeveloperProfile developer;
  final List<InvestorProjectUpdate> updates;
  final List<InvestorProjectDocument> documents;
  final InvestorProjectLocation? location;
  final List<InvestorProjectPlan> plans;
}

final class InvestorProjectDocument {
  const InvestorProjectDocument({required this.id, required this.name});
  final String id;
  final String name;
}
