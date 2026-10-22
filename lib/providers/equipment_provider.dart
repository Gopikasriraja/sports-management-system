import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/equipment_repository.dart';
import '../models/equipment_model.dart';
import '../models/equipment_issue_model.dart';
import '../models/equipment_return_model.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentRepository _equipmentRepository;

  StreamSubscription? _equipmentSub;
  StreamSubscription? _issuesSub;
  StreamSubscription? _returnsSub;

  EquipmentProvider({
    EquipmentRepository? equipmentRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _equipmentRepository = equipmentRepository ?? EquipmentRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<EquipmentModel> _equipmentList = [];
  List<EquipmentIssueModel> _issueLogs = [];
  List<EquipmentReturnModel> _returnLogs = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EquipmentModel> get equipmentList => _equipmentList;
  List<EquipmentIssueModel> get issueLogs => _issueLogs;
  List<EquipmentReturnModel> get returnLogs => _returnLogs;

  // 1. Dashboard summary cards calculations (Metrics)
  int get totalEquipmentCount => _equipmentList.length; // Distinct equipment types
  int get totalEquipmentUnits => _equipmentList.fold(0, (sum, item) => sum + item.quantity); // Sum of total stock
  int get availableEquipmentUnits => _equipmentList.fold(0, (sum, item) => sum + item.availableQuantity);
  int get issuedEquipmentUnits => _equipmentList.fold(0, (sum, item) => sum + item.issuedQuantity);
  int get damagedEquipmentUnits => _equipmentList.fold(0, (sum, item) => sum + item.damagedQuantity);
  int get lowStockEquipmentCount =>
      _equipmentList.where((item) => item.availableQuantity <= item.minStockLevel && item.availableQuantity > 0).length;
  int get outOfStockEquipmentCount => _equipmentList.where((item) => item.availableQuantity == 0).length;

  // Low stock alerts list
  List<EquipmentModel> get lowStockAlerts =>
      _equipmentList.where((item) => item.availableQuantity <= item.minStockLevel && item.availableQuantity > 0).toList();

  // Out of stock alerts list
  List<EquipmentModel> get outOfStockAlerts =>
      _equipmentList.where((item) => item.availableQuantity == 0).toList();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _equipmentSub = _equipmentRepository.streamEquipment().listen((list) {
      _equipmentList = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _isLoading = false;
      notifyListeners();
    });

    _issuesSub = _equipmentRepository.streamEquipmentIssues().listen((list) {
      _issueLogs = list;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      notifyListeners();
    });

    _returnsSub = _equipmentRepository.streamEquipmentReturns().listen((list) {
      _returnLogs = list;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      notifyListeners();
    });
  }

  // Fallback explicit fetch methods if needed
  Future<void> fetchEquipment() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _equipmentList = await _equipmentRepository.getEquipmentList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIssues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _issueLogs = await _equipmentRepository.getEquipmentIssues();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReturns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _returnLogs = await _equipmentRepository.getEquipmentReturns();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Equipment CRUD
  Future<bool> saveEquipment(EquipmentModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _equipmentRepository.saveEquipment(item);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Soft delete equipment
  Future<bool> deleteEquipment(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _equipmentRepository.deleteEquipment(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Issue Equipment
  Future<bool> issueEquipment(EquipmentIssueModel issue) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _equipmentRepository.issueEquipment(issue);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Return Equipment with specific return details
  Future<bool> returnEquipment(EquipmentReturnModel ret) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _equipmentRepository.returnEquipment(ret);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIssuesByStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _issueLogs = await _equipmentRepository.getIssuesByStudent(studentId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEquipmentIssue(String issueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _equipmentRepository.deleteEquipmentIssue(issueId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _equipmentSub?.cancel();
    _issuesSub?.cancel();
    _returnsSub?.cancel();
    super.dispose();
  }
}
