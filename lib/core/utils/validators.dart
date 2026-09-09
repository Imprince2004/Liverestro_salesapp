/// Utility validation helpers for forms in LiveRestro Sales.
class Validators {
  Validators._();

  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateOtp(String? value, [int length = 6]) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.length != length || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Enter a valid $length-digit OTP';
    }
    return null;
  }

  static String? validatePin(String? value, [int length = 4]) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN is required';
    }
    if (value.length != length || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Enter a valid $length-digit PIN';
    }
    return null;
  }
}
