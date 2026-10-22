import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreAuthorization {
  FirestoreAuthorization._();

  static Future<void> requireActiveActor({
    required FirebaseFirestore db,
    required String actorUid,
    required String actorRole,
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid != actorUid) {
      throw StateError('The signed-in account does not match this action.');
    }

    final actor = await db.collection('users').doc(authUid).get();
    final data = actor.data();
    if (!actor.exists ||
        (data?['status'] as String? ?? '').toLowerCase() != 'active' ||
        data?['role'] != actorRole) {
      throw StateError('The signed-in account is not authorized for this action.');
    }
  }
}
