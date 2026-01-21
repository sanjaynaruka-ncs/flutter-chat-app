import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧹 ChatClearManager
/// 🔒 SINGLE OWNER of clear & delete visibility
///
/// PRIORITY:
/// deletedAt > clearedAt
class ChatClearManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🧹 Clear chat ONLY for this user (soft clear)
  static Future<void> clearChat({
    required String conversationId,
    required String myUid,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .set(
      {
        'clearedAt.$myUid': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// 🔁 MESSAGE STREAM (DELETE + CLEAR SAFE)
  ///
  /// ✅ FIXED:
  /// - Emits on *every* message document update (status/read/delivered)
  /// - Still reacts to clearedAt / deletedAt changes
  static Stream<QuerySnapshot> messageStream({
    required String conversationId,
    required String myUid,
  }) {
    final convoRef =
        _db.collection('conversations').doc(conversationId);

    final baseMessagesRef = convoRef
        .collection('messages')
        .orderBy('createdAt');

    late StreamSubscription convoSub;
    StreamSubscription? messageSub;

    final controller = StreamController<QuerySnapshot>.broadcast();

    void attachMessageStream(Timestamp? effectiveClear) {
      messageSub?.cancel();

      final Query query = effectiveClear == null
          ? baseMessagesRef
          : baseMessagesRef.where(
              'createdAt',
              isGreaterThan: effectiveClear,
            );

      messageSub = query.snapshots().listen(
        controller.add,
        onError: controller.addError,
      );
    }

    convoSub = convoRef.snapshots().listen((convoSnap) {
      final data = convoSnap.data() as Map<String, dynamic>?;

      Timestamp? clearedAt;
      Timestamp? deletedAt;

      if (data != null) {
        // clearedAt
        if (data['clearedAt.$myUid'] is Timestamp) {
          clearedAt = data['clearedAt.$myUid'];
        } else if (data['clearedAt'] is Map &&
            data['clearedAt'][myUid] is Timestamp) {
          clearedAt = data['clearedAt'][myUid];
        }

        // deletedAt
        if (data['deletedAt.$myUid'] is Timestamp) {
          deletedAt = data['deletedAt.$myUid'];
        } else if (data['deletedAt'] is Map &&
            data['deletedAt'][myUid] is Timestamp) {
          deletedAt = data['deletedAt'][myUid];
        }
      }

      Timestamp? effectiveClear;

      if (clearedAt != null && deletedAt != null) {
        effectiveClear =
            clearedAt.compareTo(deletedAt) > 0
                ? clearedAt
                : deletedAt;
      } else {
        effectiveClear = clearedAt ?? deletedAt;
      }

      // 🔑 Re-attach message listener
      attachMessageStream(effectiveClear);
    });

    controller.onCancel = () {
      convoSub.cancel();
      messageSub?.cancel();
    };

    return controller.stream;
  }
}
