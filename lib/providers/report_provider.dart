import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/report_repository.dart';
import '../models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _reportRepository;
  StreamSubscription? _reportSub;

  ReportProvider({
    ReportRepository? reportRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _reportRepository = reportRepository ?? ReportRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _reportSub = _reportRepository.streamReports().listen((list) {
      _reports = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _reportSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<ReportModel> _reports = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ReportModel> get reports => _reports;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reportRepository.getReportsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportsByType(String type) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reportRepository.getReportsByType(type);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveReport(ReportModel report) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reportRepository.saveReport(report);
      await fetchReports();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReport(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reportRepository.deleteReport(id);
      await fetchReports();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
