import 'package:family_doc/features/documents/data/reading/expiry_date_finder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 27);
  DateTime? find(String text) => ExpiryDateFinder.find(text, now: now);

  test('RC: "Valid Till" on the same line, registration date ignored', () {
    expect(
      find('''
FORM 23A
Registration No WB02AB1234
Date of Reg. 14/03/2016
Fitness/REGN Upto: 13/03/2031
Owner NILADRI ROY'''),
      DateTime(2031, 3, 13),
    );
  });

  test('Driving licence: label above the value, DOB and issue skipped', () {
    expect(
      find('''
DL No WB01 20160012345
DOB 12-08-1996
Date of Issue 05-06-2016
Validity (NT)
04-06-2036'''),
      DateTime(2036, 6, 4),
    );
  });

  test('Passport: month names', () {
    expect(
      find('''
Date of Birth 12 AUG 1996
Date of Issue 21 JAN 2020
Date of Expiry 20 JAN 2030'''),
      DateTime(2030, 1, 20),
    );
  });

  test('Insurance: "from A to B" takes B, ISO dates', () {
    expect(
      find('Policy Period valid from 2025-12-01 to 2026-11-30'),
      DateTime(2026, 11, 30),
    );
  });

  test('An expired date is still the expiry date', () {
    expect(find('PUC Valid Upto: 10/10/2025'), DateTime(2025, 10, 10));
  });

  test('No expiry word: latest future date, never only past dates', () {
    expect(
      find('Issued 01/01/2020\nNext service 15/02/2027'),
      DateTime(2027, 2, 15),
    );
    expect(find('Marksheet\nExam held 12/05/2018\nDOB 12/08/1996'), isNull);
    expect(find('No dates here'), isNull);
  });

  test('Invalid dates are skipped', () {
    expect(ExpiryDateFinder.datesIn('31/02/2030 and 12/13/2030'), isEmpty);
    expect(ExpiryDateFinder.datesIn('Mar 5, 2031'), [DateTime(2031, 3, 5)]);
  });
}
