import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';

class ReportService {
  final FirebaseFirestore? _firestore;

  ReportService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Fetch single report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await db.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  // Save report meta record
  Future<void> saveReport(ReportModel report) async {
    try {
      await db.collection('reports').doc(report.reportId).set(report.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save report: $e');
    }
  }

  // Delete report meta record
  Future<void> deleteReport(String reportId) async {
    try {
      await db.collection('reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Fetch reports list
  Future<List<ReportModel>> getReportsList() async {
    try {
      final snapshot = await db.collection('reports').orderBy('generatedAt', descending: true).get();
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  // Filter reports by type
  Future<List<ReportModel>> getReportsByType(String type) async {
    try {
      final snapshot = await db
          .collection('reports')
          .where('type', isEqualTo: type)
          .orderBy('generatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports by type: $e');
    }
  }

  // Stream reports list
  Stream<List<ReportModel>> streamReports() {
    return db.collection('reports').orderBy('generatedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    });
  }
}
