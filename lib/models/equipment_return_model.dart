import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentReturnModel {
  final String returnId;
  final String issueId;
  final DateTime returnDate;
  final int returnedQuantity;
  final String condition; // 'Good', 'Damaged', 'Lost'
  final String remarks;
  final String returnedTo;

  EquipmentReturnModel({
    required this.returnId,
    required this.issueId,
    required this.returnDate,
    required this.returnedQuantity,
    required this.condition,
    required this.remarks,
    required this.returnedTo,
  });

  EquipmentReturnModel copyWith({
    String? returnId,
    String? issueId,
    DateTime? returnDate,
    int? returnedQuantity,
    String? condition,
    String? remarks,
    String? returnedTo,
  }) {
    return EquipmentReturnModel(
      returnId: returnId ?? this.returnId,
      issueId: issueId ?? this.issueId,
      returnDate: returnDate ?? this.returnDate,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      condition: condition ?? this.condition,
      remarks: remarks ?? this.remarks,
      returnedTo: returnedTo ?? this.returnedTo,
    );
  }

  factory EquipmentReturnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EquipmentReturnModel.fromMap(data, doc.id);
  }

  factory EquipmentReturnModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return EquipmentReturnModel(
      returnId: id,
      issueId: data['issueId'] ?? '',
      returnDate: parseDate(data['returnDate']),
      returnedQuantity: parseInt(data['returnedQuantity'] ?? 0),
      condition: data['condition'] ?? 'Good',
      remarks: data['remarks'] ?? '',
      returnedTo: data['returnedTo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'returnId': returnId,
      'issueId': issueId,
      'returnDate': Timestamp.fromDate(returnDate),
      'returnedQuantity': returnedQuantity,
      'condition': condition,
      'remarks': remarks,
      'returnedTo': returnedTo,
    };
  }

  String toJson() => json.encode(toMap());

  factory EquipmentReturnModel.fromJson(String source, String id) =>
      EquipmentReturnModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
