enum Experience { investor, landowner }

enum EntityType { individual, company, trust, stokvel }

final class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '+27 82 123 4567',
    this.address = '14 Protea Ave, Randburg, Gauteng, 2184',
    this.entity = EntityType.individual,
    this.hasProfilePhoto = true,
    this.countryCode = 'ZA',
    this.nonResident = false,
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final EntityType entity;
  final bool hasProfilePhoto;
  final String countryCode;
  final bool nonResident;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    EntityType? entity,
    bool? hasProfilePhoto,
    String? countryCode,
    bool? nonResident,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    entity: entity ?? this.entity,
    hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
    countryCode: countryCode ?? this.countryCode,
    nonResident: nonResident ?? this.nonResident,
  );
}

/// Accounts created in this session, as opposed to the seeded demo landowner.
bool isFreshLocalAccount(String? id) =>
    id != null &&
    (id.startsWith('local-investor-') || id.startsWith('local-landowner-'));
