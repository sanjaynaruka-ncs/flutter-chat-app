import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BroadcastService {
  const BroadcastService();

  /// ✅ Create a broadcast list (no messages yet)
  Future<void> createBroadcast({
    required String name,
    required List<String> recipients,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection('broadcasts')
        .add({
      'ownerId': uid,
      'name': name,
      'recipients': recipients,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
