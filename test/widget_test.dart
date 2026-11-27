import 'package:flutter_test/flutter_test.dart';
import 'package:pawnder/utils/date_format.dart';
import 'package:pawnder/utils/validators.dart';

// Small checks that run without Supabase or a phone: `flutter test`.
void main() {
  test('formatDate shows a short date', () {
    expect(formatDate(DateTime(2026, 11, 27)), 'Nov 27, 2026');
    expect(formatDate(DateTime(2026, 1, 5)), 'Jan 5, 2026');
  });

  test('formatTime shows a 12-hour time', () {
    expect(formatTime(DateTime(2026, 11, 27, 20, 5)), '8:05 PM');
    expect(formatTime(DateTime(2026, 11, 27, 0, 30)), '12:30 AM');
    expect(formatTime(DateTime(2026, 11, 27, 12, 0)), '12:00 PM');
  });

  test('validateMobileNumber accepts PH mobile numbers only', () {
    expect(validateMobileNumber('0993 456 7891'), isNull);
    expect(validateMobileNumber('+63 993 456 7891'), isNull);
    expect(validateMobileNumber('12345'), isNotNull);
    expect(validateMobileNumber(''), isNotNull);
  });

  test('validateContactEmail checks the format', () {
    expect(validateContactEmail('pawnder.appv1@gmail.com'), isNull);
    expect(validateContactEmail('not-an-email'), isNotNull);
  });
}