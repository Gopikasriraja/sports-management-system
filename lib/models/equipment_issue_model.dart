import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentIssueModel {
  final String issueId;
  final String equipmentId;
  final String studentId;
  final DateTime issueDate;
  final DateTime? returnDate;
  final String status;
  final int quantity;
  final DateTime expectedReturnDate;
  final String issuedBy;
  final String studentName;
  final String equipmentName;
  final int returnedQuantity;

  EquipmentIssueModel({
    required this.issueId,
    required this.equipmentId,
    required this.studentId,
    required this.issueDate,
    this.returnDate,
    required this.status,
    required this.quantity,
    required this.expectedReturnDate,
    required this.issuedBy,
    this.studentName = '',
    this.equipmentName = '',
    this.returnedQuantity = 0,
  });

  EquipmentIssueModel copyWith({
    String? issueId,
    String? equipmentId,
    String? studentId,
    DateTime? issueDate,
    DateTime? returnDate,
    String? status,
    int? quantity,
    DateTime? expectedReturnDate,
    String? issuedBy,
    String? studentName,
    String? equipmentName,
    int? returnedQuantity,
  }) {
    return EquipmentIssueModel(
      issueId: issueId ?? this.issueId,
      equipmentId: equipmentId ?? this.equipmentId,
      studentId: studentId ?? this.studentId,
      issueDate: issueDate ?? this.issueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      issuedBy: issuedBy ?? this.issuedBy,
      studentName: studentName ?? this.studentName,
      equipmentName: equipmentName ?? this.equipmentName,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    );
  }

  factory EquipmentIssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EquipmentIssueModel.fromMap(data, doc.id);
  }

  factory EquipmentIssueModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return null;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return EquipmentIssueModel(
      issueId: id,
      equipmentId: data['equipmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      issueDate: parseDate(data['issueDate']),
      returnDate: parseNullableDate(data['returnDate']),
      status: data['status'] ?? '',
      quantity: parseInt(data['quantity'] ?? 1),
      expectedReturnDate: parseDate(data['expectedReturnDate']),
      issuedBy: data['issuedBy'] ?? '',
      studentName: data['studentName'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      returnedQuantity: parseInt(data['returnedQuantity'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issueId': issueId,
      'equipmentId': equipmentId,
      'studentId': studentId,
      'issueDate': Timestamp.fromDate(issueDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'status': status,
      'quantity': quantity,
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'issuedBy': issuedBy,
      'studentName': studentName,
      'equipmentName': equipmentName,
      'returnedQuantity': returnedQuantity,
    };
  }

  String toJson() => json.encode(toMap());

  factory EquipmentIssueModel.fromJson(String source, String id) =>
      EquipmentIssueModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
