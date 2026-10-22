import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentModel {
  final String equipmentId;
  final String equipmentName;
  final String category;
  final int quantity;
  final int availableQuantity;
  final int issuedQuantity;
  final String condition;
  final DateTime purchaseDate;
  final double cost;
  final String brand;
  final String status;
  final String supplier;
  final String remarks;
  final int minStockLevel;
  final String equipmentImage;
  final int damagedQuantity;
  final int lostQuantity;
  final bool isDeleted;

  EquipmentModel({
    required this.equipmentId,
    required this.equipmentName,
    required this.category,
    required this.quantity,
    required this.availableQuantity,
    required this.issuedQuantity,
    required this.condition,
    required this.purchaseDate,
    required this.cost,
    this.brand = '',
    this.status = 'Available',
    this.supplier = '',
    this.remarks = '',
    this.minStockLevel = 2,
    this.equipmentImage = '',
    this.damagedQuantity = 0,
    this.lostQuantity = 0,
    this.isDeleted = false,
  });

  EquipmentModel copyWith({
    String? equipmentId,
    String? equipmentName,
    String? category,
    int? quantity,
    int? availableQuantity,
    int? issuedQuantity,
    String? condition,
    DateTime? purchaseDate,
    double? cost,
    String? brand,
    String? status,
    String? supplier,
    String? remarks,
    int? minStockLevel,
    String? equipmentImage,
    int? damagedQuantity,
    int? lostQuantity,
    bool? isDeleted,
  }) {
    return EquipmentModel(
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      issuedQuantity: issuedQuantity ?? this.issuedQuantity,
      condition: condition ?? this.condition,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      cost: cost ?? this.cost,
      brand: brand ?? this.brand,
      status: status ?? this.status,
      supplier: supplier ?? this.supplier,
      remarks: remarks ?? this.remarks,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      equipmentImage: equipmentImage ?? this.equipmentImage,
      damagedQuantity: damagedQuantity ?? this.damagedQuantity,
      lostQuantity: lostQuantity ?? this.lostQuantity,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory EquipmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EquipmentModel.fromMap(data, doc.id);
  }

  factory EquipmentModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return EquipmentModel(
      equipmentId: id,
      equipmentName: data['equipmentName'] ?? '',
      category: data['category'] ?? '',
      quantity: parseInt(data['quantity']),
      availableQuantity: parseInt(data['availableQuantity']),
      issuedQuantity: parseInt(data['issuedQuantity']),
      condition: data['condition'] ?? '',
      purchaseDate: parseDate(data['purchaseDate']),
      cost: parseDouble(data['cost']),
      brand: data['brand'] ?? '',
      status: data['status'] ?? 'Available',
      supplier: data['supplier'] ?? '',
      remarks: data['remarks'] ?? '',
      minStockLevel: parseInt(data['minStockLevel'] ?? 2),
      equipmentImage: data['equipmentImage'] ?? '',
      damagedQuantity: parseInt(data['damagedQuantity'] ?? 0),
      lostQuantity: parseInt(data['lostQuantity'] ?? 0),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'category': category,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'issuedQuantity': issuedQuantity,
      'condition': condition,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'cost': cost,
      'brand': brand,
      'status': status,
      'supplier': supplier,
      'remarks': remarks,
      'minStockLevel': minStockLevel,
      'equipmentImage': equipmentImage,
      'damagedQuantity': damagedQuantity,
      'lostQuantity': lostQuantity,
      'isDeleted': isDeleted,
    };
  }

  String toJson() => json.encode(toMap());

  factory EquipmentModel.fromJson(String source, String id) =>
      EquipmentModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
