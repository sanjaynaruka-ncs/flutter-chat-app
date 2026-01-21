import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

/// 📄 ChatDocumentService
///
/// RESPONSIBILITY:
/// - Upload document to Firebase Storage
/// - Write DOCUMENT message to Firestore
/// - Update conversation meta (lastMessage)
///
/// ❌ NO UI
/// ❌ NO navigation
/// ❌ NO optimistic logic
///
/// ✅ Sender safe
/// ✅ Receiver safe
/// ✅ Meta consistent
class ChatDocumentService {
  final String conversationId;

  ChatDocumentService(this.conversationId);

  /// 🔥 SEND DOCUMENT
  Future<void> sendDocument({
    required String localPath,
    required String fileName,
    required int fileSize,
  }) async {
    debugPrint(
      '📄📄📄 [ChatDocumentService] EXECUTING | path=$localPath | name=$fileName',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔴 [ChatDocumentService] ABORT: user is null');
      return;
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      debugPrint('🔴 [ChatDocumentService] ABORT: file missing');
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // ─────────────────────────────────────────────
    // 1️⃣ UPLOAD TO STORAGE
    // ─────────────────────────────────────────────
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_documents')
        .child(conversationId)
        .child('${now.millisecondsSinceEpoch}_$fileName');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    debugPrint('🟢 [ChatDocumentService] Upload SUCCESS');

    // ─────────────────────────────────────────────
    // 2️⃣ WRITE FIRESTORE MESSAGE (AUTHORITATIVE)
    // ─────────────────────────────────────────────
    final payload = {
      'type': 'document',
      'path': downloadUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'senderId': user.uid,
      'createdAt': now,
      'status': 'sent', // 🔑 CRITICAL
    };

    debugPrint(
      '📄📄📄 [ChatDocumentService] FIRESTORE PAYLOAD → $payload',
    );

    await messagesRef.add(payload);

    debugPrint('🟢 [ChatDocumentService] Firestore document written');

    // ─────────────────────────────────────────────
    // 3️⃣ UPDATE CONVERSATION META
    // ─────────────────────────────────────────────
    final messageService = ChatMessageService(conversationId);

    await messageService.updateAfterDocumentSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint('🟢 [ChatDocumentService] Conversation meta updated');
  }
}
