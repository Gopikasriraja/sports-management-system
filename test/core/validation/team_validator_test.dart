import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/core/validation/team_validator.dart';

void main() {
  group('TeamValidator', () {
    test('requires a team name and sport', () {
      expect(TeamValidator.validateName('  '), isNotNull);
      expect(TeamValidator.validateSport(null), isNotNull);
      expect(TeamValidator.validateName('Varsity'), isNull);
      expect(TeamValidator.validateSport('Basketball'), isNull);
    });

    test('detects duplicate member IDs without rejecting new members', () {
      expect(
        TeamValidator.hasDuplicateMember(['student-1'], 'student-1'),
        isTrue,
      );
      expect(
        TeamValidator.hasDuplicateMember(['student-1'], 'student-2'),
        isFalse,
      );
    });
  });
}
