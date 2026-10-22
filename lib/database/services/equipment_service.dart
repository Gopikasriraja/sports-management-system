import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/equipment_model.dart';
import '../../models/equipment_issue_model.dart';
import '../../models/equipment_return_model.dart';

class EquipmentService {
  final FirebaseFirestore? _firestore;

  EquipmentService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // 1. Equipment Inventory CRUD (Filtering soft-deleted items locally for safety)

  // Fetch single equipment by ID
  Future<EquipmentModel?> getEquipmentById(String equipmentId) async {
    try {
      final doc = await db.collection('sports_equipment').doc(equipmentId).get();
      if (doc.exists) {
        final item = EquipmentModel.fromFirestore(doc);
        return item.isDeleted ? null : item;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch equipment: $e');
    }
  }

  // Save or update equipment
  Future<void> saveEquipment(EquipmentModel item) async {
    try {
      await db.collection('sports_equipment').doc(item.equipmentId).set(item.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save equipment: $e');
    }
  }

  // Soft delete equipment
  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await db.collection('sports_equipment').doc(equipmentId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to soft delete equipment: $e');
    }
  }

  // Fetch non-deleted equipment list
  Future<List<EquipmentModel>> getEquipmentList() async {
    try {
      final snapshot = await db.collection('sports_equipment').get();
      return snapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .where((item) => !item.isDeleted)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch equipment list: $e');
    }
  }

  // Stream non-deleted equipment
  Stream<List<EquipmentModel>> streamEquipment() {
    return db.collection('sports_equipment').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .where((item) => !item.isDeleted)
          .toList();
    });
  }

  // 2. Equipment Issues Transactions

  // Issue equipment (transactional)
  Future<void> issueEquipment(EquipmentIssueModel issue) async {
    try {
      await db.runTransaction((transaction) async {
        final equipRef = db.collection('sports_equipment').doc(issue.equipmentId);
        final equipDoc = await transaction.get(equipRef);

        if (!equipDoc.exists) {
          throw Exception('Equipment does not exist.');
        }

        final equip = EquipmentModel.fromFirestore(equipDoc);
        if (equip.isDeleted) {
          throw Exception('Equipment has been deleted.');
        }
        if (equip.availableQuantity < issue.quantity) {
          throw Exception('Requested quantity (${issue.quantity}) exceeds available stock (${equip.availableQuantity}).');
        }

        // Write issue record
        final issueRef = db.collection('equipment_issues').doc(issue.issueId);
        transaction.set(issueRef, issue.toMap());

        // Update equipment quantities and status
        final newAvail = equip.availableQuantity - issue.quantity;
        final newIssued = equip.issuedQuantity + issue.quantity;
        
        String status = 'Available';
        if (newAvail == 0) {
          status = 'Out of Stock';
        } else if (newAvail <= equip.minStockLevel) {
          status = 'Low Stock';
        }

        transaction.update(equipRef, {
          'availableQuantity': newAvail,
          'issuedQuantity': newIssued,
          'status': status,
        });
      });
    } catch (e) {
      throw Exception('Failed to issue equipment: $e');
    }
  }

  // 3. Equipment Returns Transactions

  // Record a return log and update stock values
  Future<void> returnEquipment(EquipmentReturnModel ret) async {
    try {
      await db.runTransaction((transaction) async {
        final issueRef = db.collection('equipment_issues').doc(ret.issueId);
        final issueDoc = await transaction.get(issueRef);

        if (!issueDoc.exists) {
          throw Exception('Issue log record not found.');
        }

        final issue = EquipmentIssueModel.fromFirestore(issueDoc);
        final remaining = issue.quantity - issue.returnedQuantity;

        if (ret.returnedQuantity > remaining) {
          throw Exception('Returned quantity (${ret.returnedQuantity}) exceeds remaining issued quantity ($remaining).');
        }

        // Create return document
        final returnRef = db.collection('equipment_returns').doc(ret.returnId);
        transaction.set(returnRef, ret.toMap());

        // Update issue record
        final newReturnedQty = issue.returnedQuantity + ret.returnedQuantity;
        final isFullyReturned = newReturnedQty >= issue.quantity;
        
        transaction.update(issueRef, {
          'returnedQuantity': newReturnedQty,
          'status': isFullyReturned ? 'returned' : 'partially_returned',
          'returnDate': Timestamp.fromDate(ret.returnDate),
        });

        // Read and update equipment inventory
        final equipRef = db.collection('sports_equipment').doc(issue.equipmentId);
        final equipDoc = await transaction.get(equipRef);

        if (!equipDoc.exists) {
          throw Exception('Equipment inventory details not found.');
        }

        final equip = EquipmentModel.fromFirestore(equipDoc);

        final newIssued = equip.issuedQuantity - ret.returnedQuantity;
        int newAvail = equip.availableQuantity;
        int newDamaged = equip.damagedQuantity;
        int newLost = equip.lostQuantity;
        int newTotal = equip.quantity;

        if (ret.condition == 'Good') {
          newAvail += ret.returnedQuantity;
        } else if (ret.condition == 'Damaged') {
          newDamaged += ret.returnedQuantity;
        } else if (ret.condition == 'Lost') {
          newLost += ret.returnedQuantity;
          newTotal -= ret.returnedQuantity;
        }

        String newStatus = 'Available';
        if (newAvail == 0) {
          newStatus = 'Out of Stock';
        } else if (newAvail <= equip.minStockLevel) {
          newStatus = 'Low Stock';
        }

        transaction.update(equipRef, {
          'quantity': newTotal,
          'availableQuantity': newAvail,
          'issuedQuantity': newIssued,
          'damagedQuantity': newDamaged,
          'lostQuantity': newLost,
          'status': newStatus,
        });
      });
    } catch (e) {
      throw Exception('Failed to record equipment return: $e');
    }
  }

  // Delete an equipment issue record
  Future<void> deleteEquipmentIssue(String issueId) async {
    try {
      await db.collection('equipment_issues').doc(issueId).delete();
    } catch (e) {
      throw Exception('Failed to delete equipment issue: $e');
    }
  }

  // Fetch all issues
  Future<List<EquipmentIssueModel>> getEquipmentIssues() async {
    try {
      final snapshot = await db.collection('equipment_issues').orderBy('issueDate', descending: true).get();
      return snapshot.docs.map((doc) => EquipmentIssueModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch equipment issues: $e');
    }
  }

  // Fetch equipment issues filtered by student
  Future<List<EquipmentIssueModel>> getIssuesByStudent(String studentId) async {
    try {
      final snapshot = await db
          .collection('equipment_issues')
          .where('studentId', isEqualTo: studentId)
          .orderBy('issueDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => EquipmentIssueModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch equipment issues by student: $e');
    }
  }

  // Stream equipment issues
  Stream<List<EquipmentIssueModel>> streamEquipmentIssues() {
    return db.collection('equipment_issues').orderBy('issueDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EquipmentIssueModel.fromFirestore(doc)).toList();
    });
  }

  // Fetch all returns
  Future<List<EquipmentReturnModel>> getEquipmentReturns() async {
    try {
      final snapshot = await db.collection('equipment_returns').orderBy('returnDate', descending: true).get();
      return snapshot.docs.map((doc) => EquipmentReturnModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch returns list: $e');
    }
  }

  // Stream equipment returns
  Stream<List<EquipmentReturnModel>> streamEquipmentReturns() {
    return db.collection('equipment_returns').orderBy('returnDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EquipmentReturnModel.fromFirestore(doc)).toList();
    });
  }
}
