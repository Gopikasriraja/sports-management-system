import '../../models/student_model.dart';
import '../services/student_service.dart';

class StudentRepository {
  final StudentService _studentService;

  StudentRepository({StudentService? studentService}) : _studentService = studentService ?? StudentService();

  Future<StudentModel?> getStudent(String studentId) => _studentService.getStudent(studentId);

  Future<bool> isRegisterNumberAvailable(
    String registerNumber, {
    required String actorUid,
    required String actorRole,
    String? excludingStudentId,
    String? excludingEmail,
  }) => _studentService.isRegisterNumberAvailable(
    registerNumber,
    actorUid: actorUid,
    actorRole: actorRole,
    excludingStudentId: excludingStudentId,
    excludingEmail: excludingEmail,
  );

  Future<void> saveStudent(
    StudentModel student, {
    required String actorUid,
    required String actorRole,
  }) => _studentService.saveStudent(
    student,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<void> deleteStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) => _studentService.deleteStudent(
    studentId,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Stream<List<StudentModel>> streamStudents() => _studentService.streamStudents();

  Future<List<StudentModel>> getStudentsList() => _studentService.getStudentsList();

  Future<List<StudentModel>> getStudentsByDepartment(String department) =>
      _studentService.getStudentsByDepartment(department);

  Future<List<StudentModel>> getStudentsBySport(String sport) =>
      _studentService.getStudentsBySport(sport);

  Future<List<StudentModel>> searchStudents(String query) =>
      _studentService.searchStudents(query);
}
