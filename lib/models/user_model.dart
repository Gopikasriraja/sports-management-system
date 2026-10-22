import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String department;
  final String year;
  final String registerNumber;
  final String employeeId;   // For Sports Staff
  final String phone;
  final String profileImage;
  final String status;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.year,
    required this.registerNumber,
    this.employeeId = '',
    required this.phone,
    required this.profileImage,
    required this.status,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? department,
    String? year,
    String? registerNumber,
    String? employeeId,
    String? phone,
    String? profileImage,
    String? status,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      year: year ?? this.year,
      registerNumber: registerNumber ?? this.registerNumber,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      department: data['department'] ?? '',
      year: data['year'] ?? '',
      registerNumber: data['registerNumber'] ?? '',
      employeeId: data['employeeId'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'year': year,
      'registerNumber': registerNumber,
      'registerNumberNormalized': registerNumber.trim().toLowerCase(),
      'employeeId': employeeId,
      'phone': phone,
      'profileImage': profileImage,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source, String id) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
