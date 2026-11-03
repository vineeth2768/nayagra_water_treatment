import 'package:flutter_test/flutter_test.dart';
import 'package:nayagra_water_treatment/core/utils/date_formatter.dart';
import 'package:nayagra_water_treatment/core/utils/validators.dart';
import 'package:nayagra_water_treatment/core/constants/app_constants.dart';

void main() {
  group('Six-Month Service Scheduling Engine Tests', () {
    test('Calculates exactly 6 months with day-of-month clamping', () {
      // 01 January 2026 -> 01 July 2026
      final install1 = DateTime(2026, 1, 1);
      final service1 = DateFormatter.addMonths(install1, AppConstants.defaultServiceIntervalMonths);
      expect(service1.year, 2026);
      expect(service1.month, 7);
      expect(service1.day, 1);

      // Subsequent service: 01 July 2026 -> 01 January 2027
      final service2 = DateFormatter.addMonths(service1, AppConstants.defaultServiceIntervalMonths);
      expect(service2.year, 2027);
      expect(service2.month, 1);
      expect(service2.day, 1);

      // Month end clamping: 31 August -> 28 February (or 29)
      final installAug31 = DateTime(2025, 8, 31);
      final serviceFeb = DateFormatter.addMonths(installAug31, 6);
      expect(serviceFeb.year, 2026);
      expect(serviceFeb.month, 2);
      expect(serviceFeb.day, 28);
    });

    test('Identifies overdue and due soon intervals', () {
      final now = DateTime.now();
      final pastDate = DateTime(now.year, now.month - 1, now.day);
      final futureDate = DateTime(now.year, now.month + 3, now.day);

      expect(DateFormatter.isOverdue(pastDate), isTrue);
      expect(DateFormatter.isOverdue(futureDate), isFalse);
    });

    test('Validates Indian, UAE, and International phone numbers up to 15 digits', () {
      // Valid Indian phone
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('+91 9876543210'), isNull);

      // Valid UAE numbers
      expect(Validators.phone('+971 50 123 4567'), isNull);
      expect(Validators.phone('0501234567'), isNull);
      expect(Validators.phone('+97141234567'), isNull);
      expect(Validators.phone('00971501234567'), isNull); // 14 digits

      // Invalid (too short or too long)
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('1234567890123456'), isNotNull); // 16 digits
    });
  });
}
