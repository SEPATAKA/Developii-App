import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class InvestorRepresentative {
  const InvestorRepresentative({
    required this.name,
    required this.identityNumber,
  });
  final String name;
  final String identityNumber;
}

final class InvestorRegistration {
  const InvestorRegistration({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.entity,
    this.registrationNumber = '',
    this.representatives = const [],
    this.nonResident = false,
    this.countryCode = 'ZA',
  });
  final String name;
  final String email;
  final String phone;
  final String password;
  final EntityType entity;
  final String registrationNumber;
  final List<InvestorRepresentative> representatives;
  final bool nonResident;
  final String countryCode;
}
