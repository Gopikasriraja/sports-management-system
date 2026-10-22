import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/core/validation/student_registration_validator.dart';
import 'package:sports_management_system/models/student_model.dart';

void main() {
  group('StudentRegistrationValidator', () {
    test('requires a name and register number', () {
      expect(StudentRegistrationValidator.validateName('  '), isNotNull);
      expect(
        StudentRegistrationValidator.validateRegisterNumber(''),
        isNotNull,
      );
      expect(StudentRegistrationValidator.validateName('A Student'), isNull);
      expect(
        StudentRegistrationValidator.validateRegisterNumber('REG-1'),
        isNull,
      );
    });

    test('validates email format', () {
      expect(
        StudentRegistrationValidator.validateEmail('not-an-email'),
        isNotNull,
      );
      expect(
        StudentRegistrationValidator.validateEmail('student@example.edu'),
        isNull,
      );
    });

    test(
      'normalizes register numbers and allows excluding the edited record',
      () {
        final students = [
          _student('one', 'MRCAS-001'),
          _student('two', 'MRCAS-002'),
        ];
        expect(
          StudentRegistrationValidator.isRegisterNumberDuplicate(
            ' mrcas-001 ',
            students,
          ),
          isTrue,
        );
        expect(
          StudentRegistrationValidator.isRegisterNumberDuplicate(
            ' mrcas-001 ',
            students,
            excludingStudentId: 'one',
          ),
          isFalse,
        );
        expect(
          StudentRegistrationValidator.normalizeRegisterNumber(' AbC '),
          'abc',
        );
      },
    );
  });
}

StudentModel _student(String id, String registerNumber) => StudentModel(
  studentId: id,
  registerNumber: registerNumber,
  name: 'Student $id',
  department: 'Sports',
  year: '1',
  section: 'A',
  gender: '',
  phone: '',
  email: '$id@example.edu',
  bloodGroup: '',
  address: '',
  sports: const [],
  profileImage: '',
  createdAt: DateTime(2025),
);
