import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class LocalAttachment {
  const LocalAttachment({
    required this.id,
    required this.name,
    this.bytes = 120000,
  });
  final String id;
  final String name;
  final int bytes;
}

final class SubmissionDraft {
  const SubmissionDraft({
    this.id = 'new-draft',
    this.step = 1,
    this.name = '',
    this.legalDescription = '',
    this.propertyNumber = '',
    this.propertyType = '',
    this.size = '',
    this.unit = '',
    this.deedsOffice = '',
    this.address = '',
    this.town = '',
    this.country = '',
    this.monthlyLease = '',
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.latitude = '',
    this.longitude = '',
    this.photos = const [],
    this.documents = const {},
    this.entity = EntityType.individual,
    this.deal = '',
    this.price = '',
    this.notes = '',
    this.coOwners = false,
    this.hasValuation = false,
    this.accepted = false,
  });
  final String id;
  final int step;
  final String name;
  final String legalDescription;
  final String propertyNumber;
  final String propertyType;
  final String size;
  final String unit;
  final String deedsOffice;
  final String address;
  final String town;
  final String country;
  final String monthlyLease;
  final String city;
  final String province;
  final String postalCode;
  final String latitude;
  final String longitude;
  final List<LocalAttachment> photos;
  final Map<String, LocalAttachment> documents;
  final EntityType entity;
  final String deal;
  final String price;
  final String notes;
  final bool coOwners;
  final bool hasValuation;
  final bool accepted;

  SubmissionDraft copyWith({
    int? step,
    String? name,
    String? legalDescription,
    String? propertyNumber,
    String? propertyType,
    String? size,
    String? unit,
    String? deedsOffice,
    String? address,
    String? town,
    String? country,
    String? monthlyLease,
    String? city,
    String? province,
    String? postalCode,
    String? latitude,
    String? longitude,
    List<LocalAttachment>? photos,
    Map<String, LocalAttachment>? documents,
    EntityType? entity,
    String? deal,
    String? price,
    String? notes,
    bool? coOwners,
    bool? hasValuation,
    bool? accepted,
  }) => SubmissionDraft(
    id: id,
    step: step ?? this.step,
    name: name ?? this.name,
    legalDescription: legalDescription ?? this.legalDescription,
    propertyNumber: propertyNumber ?? this.propertyNumber,
    propertyType: propertyType ?? this.propertyType,
    size: size ?? this.size,
    unit: unit ?? this.unit,
    deedsOffice: deedsOffice ?? this.deedsOffice,
    address: address ?? this.address,
    town: town ?? this.town,
    country: country ?? this.country,
    monthlyLease: monthlyLease ?? this.monthlyLease,
    city: city ?? this.city,
    province: province ?? this.province,
    postalCode: postalCode ?? this.postalCode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    photos: List.unmodifiable(photos ?? this.photos),
    documents: Map.unmodifiable(documents ?? this.documents),
    entity: entity ?? this.entity,
    deal: deal ?? this.deal,
    price: price ?? this.price,
    notes: notes ?? this.notes,
    coOwners: coOwners ?? this.coOwners,
    hasValuation: hasValuation ?? this.hasValuation,
    accepted: accepted ?? this.accepted,
  );
}
