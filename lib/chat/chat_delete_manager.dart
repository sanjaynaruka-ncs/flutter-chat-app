import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDeleteManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Future<void> deleteChat({
    required String conversationId,
    required String myUid,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .set(
      {
        // 🔴 Hide chat from chat list
        'deletedAt.$myUid': Timestamp.now(),

        // 🧹 Permanently hide old messages for this user
        'clearedAt.$myUid': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }
}
