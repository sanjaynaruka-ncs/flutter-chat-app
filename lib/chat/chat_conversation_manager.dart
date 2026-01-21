import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/chat_message_list.dart';

class ChatConversationManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // 🔑 CONVERSATION CREATION (PURE, SAFE)
  // ─────────────────────────────────────────────
  static Future<String> getOrCreateDirectConversation({
    required String otherUid,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    // Deterministic conversationId (order-independent)
    final participants = [myUid, otherUid]..sort();
    final conversationId = participants.join('_');

    final ref =
        _db.collection('conversations').doc(conversationId);

    final snap = await ref.get();

    // If already exists → reuse
    if (snap.exists) {
      return conversationId;
    }

    // Create once with safe defaults
    await ref.set({
      'participants': participants,
      'isGroup': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'unread': {
        myUid: 0,
        otherUid: 0,
      },
      'clearedAt': {},
      'deletedAt': {},
      'blocked': {},
      'isStarred': false,
    });

    return conversationId;
  }

  // ─────────────────────────────────────────────
  // 🔁 OPTIMISTIC TEXT RECONCILIATION (UI-ONLY)
  // ─────────────────────────────────────────────
  static void reconcileOptimisticMessages({
  required List<ChatMessageUi> optimistic,
  required List<QueryDocumentSnapshot> firestoreDocs,
}) {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;

  optimistic.removeWhere((item) {
    if (item is ChatBubbleUi && item.isMe) {
      return firestoreDocs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // 🔑 SAME MESSAGE FOUND IN FIRESTORE → REMOVE OPTIMISTIC
        return data['type'] == 'text' &&
            data['senderId'] == myUid &&
            data['text'] == item.text;
      });
    }
    return false;
  });
}

}
