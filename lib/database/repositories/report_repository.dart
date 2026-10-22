import '../../models/report_model.dart';
import '../services/report_service.dart';

class ReportRepository {
  final ReportService _reportService;

  ReportRepository({ReportService? reportService}) : _reportService = reportService ?? ReportService();

  Future<ReportModel?> getReportById(String reportId) => _reportService.getReportById(reportId);

  Future<void> saveReport(ReportModel report) => _reportService.saveReport(report);

  Future<void> deleteReport(String reportId) => _reportService.deleteReport(reportId);

  Future<List<ReportModel>> getReportsList() => _reportService.getReportsList();

  Future<List<ReportModel>> getReportsByType(String type) => _reportService.getReportsByType(type);

  Stream<List<ReportModel>> streamReports() => _reportService.streamReports();
}
