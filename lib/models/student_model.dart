import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String registerNumber;
  final String name;
  final String department;
  final String subDepartment;
  final String year;
  final String section;
  final String gender;
  final String dateOfBirth;
  final String phone;
  final String email;
  final String bloodGroup;
  final String address;
  final String parentName;
  final String parentMobileNumber;
  final List<String> sports;
  final String profileImage;
  final DateTime createdAt;
  final String status;
  final bool isSportsQuota;
  final String admissionYear;
  
  // New Enhanced Profile Fields
  final String rollNumber;
  final String aadhaarNumber;
  final String alternateMobileNumber;
  final String city;
  final String district;
  final String state;
  final String pinCode;
  final String fatherName;
  final String motherName;
  final String guardianName;
  final String currentSemester;
  final String academicStatus;
  final String sportsCategory;
  final String coachName;
  final String practiceBatch;
  final String jerseyNumber;
  final String height;
  final String weight;
  final String medicalIssues;
  final String emergencyContact;
  StudentModel({
    required this.studentId,
    required this.registerNumber,
    required this.name,
    required this.department,
    this.subDepartment = '',
    required this.year,
    required this.section,
    required this.gender,
    this.dateOfBirth = '',
    required this.phone,
    required this.email,
    required this.bloodGroup,
    required this.address,
    this.parentName = '',
    this.parentMobileNumber = '',
    required this.sports,
    required this.profileImage,
    required this.createdAt,
    this.status = 'Active',
    this.isSportsQuota = false,
    this.admissionYear = '',
    this.rollNumber = '',
    this.aadhaarNumber = '',
    this.alternateMobileNumber = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.pinCode = '',
    this.fatherName = '',
    this.motherName = '',
    this.guardianName = '',
    this.currentSemester = '',
    this.academicStatus = '',
    this.sportsCategory = '',
    this.coachName = '',
    this.practiceBatch = '',
    this.jerseyNumber = '',
    this.height = '',
    this.weight = '',
    this.medicalIssues = '',
    this.emergencyContact = '',
  });

  StudentModel copyWith({
    String? studentId,
    String? registerNumber,
    String? name,
    String? department,
    String? subDepartment,
    String? year,
    String? section,
    String? gender,
    String? dateOfBirth,
    String? phone,
    String? email,
    String? bloodGroup,
    String? address,
    String? parentName,
    String? parentMobileNumber,
    List<String>? sports,
    String? profileImage,
    DateTime? createdAt,
    String? status,
    bool? isSportsQuota,
    String? admissionYear,
    String? rollNumber,
    String? aadhaarNumber,
    String? alternateMobileNumber,
    String? city,
    String? district,
    String? state,
    String? pinCode,
    String? fatherName,
    String? motherName,
    String? guardianName,
    String? currentSemester,
    String? academicStatus,
    String? sportsCategory,
    String? coachName,
    String? practiceBatch,
    String? jerseyNumber,
    String? height,
    String? weight,
    String? medicalIssues,
    String? emergencyContact,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      registerNumber: registerNumber ?? this.registerNumber,
      name: name ?? this.name,
      department: department ?? this.department,
      subDepartment: subDepartment ?? this.subDepartment,
      year: year ?? this.year,
      section: section ?? this.section,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      parentName: parentName ?? this.parentName,
      parentMobileNumber: parentMobileNumber ?? this.parentMobileNumber,
      sports: sports ?? this.sports,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isSportsQuota: isSportsQuota ?? this.isSportsQuota,
      admissionYear: admissionYear ?? this.admissionYear,
      rollNumber: rollNumber ?? this.rollNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      alternateMobileNumber: alternateMobileNumber ?? this.alternateMobileNumber,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      guardianName: guardianName ?? this.guardianName,
      currentSemester: currentSemester ?? this.currentSemester,
      academicStatus: academicStatus ?? this.academicStatus,
      sportsCategory: sportsCategory ?? this.sportsCategory,
      coachName: coachName ?? this.coachName,
      practiceBatch: practiceBatch ?? this.practiceBatch,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      medicalIssues: medicalIssues ?? this.medicalIssues,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel.fromMap(data, doc.id);
  }

  factory StudentModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    final sportsData = data['sports'];
    List<String> sportsList = [];
    if (sportsData is List) {
      sportsList = sportsData.map((e) => e.toString()).toList();
    }

    return StudentModel(
      studentId: id,
      registerNumber: data['registerNumber'] ?? '',
      name: data['name'] ?? '',
      department: data['department'] ?? '',
      subDepartment: data['subDepartment'] ?? '',
      year: data['year'] ?? '',
      section: data['section'] ?? '',
      gender: data['gender'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      address: data['address'] ?? '',
      parentName: data['parentName'] ?? '',
      parentMobileNumber: data['parentMobileNumber'] ?? '',
      sports: sportsList,
      profileImage: data['profileImage'] ?? '',
      createdAt: parseDate(data['createdAt']),
      status: data['status'] ?? 'Active',
      isSportsQuota: data['isSportsQuota'] ?? false,
      admissionYear: data['admissionYear'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      aadhaarNumber: data['aadhaarNumber'] ?? '',
      alternateMobileNumber: data['alternateMobileNumber'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      pinCode: data['pinCode'] ?? '',
      fatherName: data['fatherName'] ?? '',
      motherName: data['motherName'] ?? '',
      guardianName: data['guardianName'] ?? '',
      currentSemester: data['currentSemester'] ?? '',
      academicStatus: data['academicStatus'] ?? '',
      sportsCategory: data['sportsCategory'] ?? '',
      coachName: data['coachName'] ?? '',
      practiceBatch: data['practiceBatch'] ?? '',
      jerseyNumber: data['jerseyNumber'] ?? '',
      height: data['height'] ?? '',
      weight: data['weight'] ?? '',
      medicalIssues: data['medicalIssues'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'registerNumber': registerNumber,
      'registerNumberNormalized': registerNumber.trim().toLowerCase(),
      'name': name,
      'department': department,
      'subDepartment': subDepartment,
      'year': year,
      'section': section,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'phone': phone,
      'email': email,
      'bloodGroup': bloodGroup,
      'address': address,
      'parentName': parentName,
      'parentMobileNumber': parentMobileNumber,
      'sports': sports,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'isSportsQuota': isSportsQuota,
      'admissionYear': admissionYear,
      'rollNumber': rollNumber,
      'aadhaarNumber': aadhaarNumber,
      'alternateMobileNumber': alternateMobileNumber,
      'city': city,
      'district': district,
      'state': state,
      'pinCode': pinCode,
      'fatherName': fatherName,
      'motherName': motherName,
      'guardianName': guardianName,
      'currentSemester': currentSemester,
      'academicStatus': academicStatus,
      'sportsCategory': sportsCategory,
      'coachName': coachName,
      'practiceBatch': practiceBatch,
      'jerseyNumber': jerseyNumber,
      'height': height,
      'weight': weight,
      'medicalIssues': medicalIssues,
      'emergencyContact': emergencyContact,
    };
  }

  String toJson() => json.encode(toMap());

  factory StudentModel.fromJson(String source, String id) =>
      StudentModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
