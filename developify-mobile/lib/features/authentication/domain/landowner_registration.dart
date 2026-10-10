import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class LandownerRegistration {
  const LandownerRegistration({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.entity,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final EntityType entity;
}
