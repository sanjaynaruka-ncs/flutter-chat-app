import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

/// 🔊 ChatAudioService
/// SINGLE RESPONSIBILITY:
/// - Upload audio (.m4a) to Firebase Storage
/// - Write AUDIO message document to Firestore
/// - Update conversation meta via ChatMessageService
///
/// ❌ NO UI
/// ❌ NO widgets
/// ❌ NO optimistic logic
///
/// ✅ Sender safe
/// ✅ Receiver safe
/// ✅ Lifecycle safe
class ChatAudioService {
  final String conversationId;

  ChatAudioService(this.conversationId);

  /// 🔥 SEND AUDIO MESSAGE (ENABLED)
  Future<void> sendAudio({
    required String localAudioPath,
    required int durationMs,
    required String clientId,
  }) async {
    debugPrint(
      '🔊 [ChatAudioService] sendAudio | path=$localAudioPath | duration=${durationMs}ms | clientId=$clientId',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔴 [ChatAudioService] ABORT: user is null');
      return;
    }

    final file = File(localAudioPath);
    if (!file.existsSync()) {
      debugPrint('🔴 [ChatAudioService] ABORT: audio file missing');
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // ─────────────────────────────────────────────
    // 1️⃣ UPLOAD AUDIO TO STORAGE
    // ─────────────────────────────────────────────
    debugPrint('🔊 [ChatAudioService] Uploading audio to Storage');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_audio')
        .child(conversationId)
        .child('${now.millisecondsSinceEpoch}_${user.uid}.m4a');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    debugPrint(
      '🟢 [ChatAudioService] Upload SUCCESS | url=$downloadUrl',
    );

    // ─────────────────────────────────────────────
    // 2️⃣ WRITE AUDIO MESSAGE (WITH STATUS)
    // ─────────────────────────────────────────────
    await messagesRef.add({
      'type': 'audio',
      'path': downloadUrl,
      'durationMs': durationMs,
      'senderId': user.uid,
      'createdAt': now,
      'clientId': clientId,
      'status': 'sent', // ✅ REQUIRED FOR TICKS
    });

    debugPrint(
      '🟢 [ChatAudioService] Firestore AUDIO message written',
    );

    // ─────────────────────────────────────────────
    // 3️⃣ UPDATE CONVERSATION META
    // ─────────────────────────────────────────────
    final messageService = ChatMessageService(conversationId);

    await messageService.updateAfterAudioSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint(
      '🟢 [ChatAudioService] Conversation meta updated',
    );
  }
}
