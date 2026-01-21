import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  static Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .add({
      'isGroup': true,
      'groupName': name,
      'participants': [uid, ...memberIds],
      'createdBy': uid,
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': '',
    });

    return doc.id;
  }
}
