import '../../models/equipment_model.dart';
import '../../models/equipment_issue_model.dart';
import '../../models/equipment_return_model.dart';
import '../services/equipment_service.dart';

class EquipmentRepository {
  final EquipmentService _equipmentService;

  EquipmentRepository({EquipmentService? equipmentService})
      : _equipmentService = equipmentService ?? EquipmentService();

  Future<EquipmentModel?> getEquipmentById(String equipmentId) =>
      _equipmentService.getEquipmentById(equipmentId);

  Future<void> saveEquipment(EquipmentModel item) => _equipmentService.saveEquipment(item);

  Future<void> deleteEquipment(String equipmentId) => _equipmentService.deleteEquipment(equipmentId);

  Future<List<EquipmentModel>> getEquipmentList() => _equipmentService.getEquipmentList();

  Stream<List<EquipmentModel>> streamEquipment() => _equipmentService.streamEquipment();

  Future<void> issueEquipment(EquipmentIssueModel issue) => _equipmentService.issueEquipment(issue);

  Future<void> returnEquipment(EquipmentReturnModel ret) =>
      _equipmentService.returnEquipment(ret);

  Future<void> deleteEquipmentIssue(String issueId) => _equipmentService.deleteEquipmentIssue(issueId);

  Future<List<EquipmentIssueModel>> getEquipmentIssues() => _equipmentService.getEquipmentIssues();

  Future<List<EquipmentIssueModel>> getIssuesByStudent(String studentId) =>
      _equipmentService.getIssuesByStudent(studentId);

  Stream<List<EquipmentIssueModel>> streamEquipmentIssues() => _equipmentService.streamEquipmentIssues();

  Future<List<EquipmentReturnModel>> getEquipmentReturns() => _equipmentService.getEquipmentReturns();

  Stream<List<EquipmentReturnModel>> streamEquipmentReturns() => _equipmentService.streamEquipmentReturns();
}
