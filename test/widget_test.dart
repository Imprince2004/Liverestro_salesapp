import 'package:flutter_test/flutter_test.dart';
import 'package:liverestro_sales/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validatePhone returns null for valid 10-digit phone', () {
      final result = Validators.validatePhone('9876543210');
      expect(result, isNull);
    });

    test('validatePhone returns error message for invalid phone', () {
      final result = Validators.validatePhone('123');
      expect(result, 'Enter a valid 10-digit phone number');
    });

    test('validateOtp returns null for valid 6-digit OTP', () {
      final result = Validators.validateOtp('123456');
      expect(result, isNull);
    });

    test('validatePin returns null for valid 4-digit PIN', () {
      final result = Validators.validatePin('1234');
      expect(result, isNull);
    });
  });
}
