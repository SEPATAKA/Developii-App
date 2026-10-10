abstract final class Validation {
  static String? email(String value) {
    if (value.trim().isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Enter your password';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? required(String value, String label) =>
      value.trim().isEmpty ? 'Enter $label' : null;

  static String? positiveNumber(String value, String label) {
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a valid $label';
    }
    return null;
  }
}
