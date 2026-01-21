import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

/// 👤 ChatContactService
///
/// RESPONSIBILITY:
/// - Write CONTACT message to Firestore
/// - Update conversation meta (lastMessage, unread, updatedAt)
///
/// ❌ NO UI
/// ❌ NO widgets
/// ❌ NO optimistic logic
///
/// ✅ Sender safe
/// ✅ Receiver safe
/// ✅ Meta consistent with other services
/// ✅ STATUS FIELD ADDED (sent → delivered → read)
class ChatContactService {
  final String conversationId;

  /// 🔑 META UPDATER (REQUIRED)
  late final ChatMessageService _messageService;

  ChatContactService(this.conversationId) {
    _messageService = ChatMessageService(conversationId);
  }

  // ─────────────────────────────────────────────
  // 🔥 SEND CONTACT MESSAGE
  // ─────────────────────────────────────────────
  Future<void> sendContact({
    required String name,
    required String phone,
  }) async {
    debugPrint(
      '👤 [ChatContactService] sendContact | name=$name | phone=$phone',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔴 [ChatContactService] ABORT: user is null');
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // ─────────────────────────────────────────────
    // 1️⃣ WRITE CONTACT MESSAGE (STATUS = sent)
    // ─────────────────────────────────────────────
    await messagesRef.add({
      'type': 'contact',
      'name': name,
      'phone': phone,
      'senderId': user.uid,
      'createdAt': now,
      'status': 'sent', // ✅ REQUIRED FOR TICKS
    });

    debugPrint('🟢 [ChatContactService] Contact message written');

    // ─────────────────────────────────────────────
    // 2️⃣ UPDATE CONVERSATION META
    // ─────────────────────────────────────────────
    await _messageService.updateAfterContactSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint('🟢 [ChatContactService] Conversation meta updated');
  }
}
