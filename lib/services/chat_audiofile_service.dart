import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

class ChatAudioFileService {
  final String conversationId;

  ChatAudioFileService(this.conversationId);

  /// 🔥 SEND AUDIO FILE
  Future<void> sendAudio({
    required String localPath,
    required String fileName,
    required int fileSize,
  }) async {
    debugPrint(
      '🎧🎧🎧 [ChatAudioFileService] EXECUTING | path=$localPath | name=$fileName',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔴 [ChatAudioFileService] ABORT: user is null');
      return;
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      debugPrint('🔴 [ChatAudioFileService] ABORT: file missing');
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
        .child('chat_audio_file')
        .child(conversationId)
        .child('${now.millisecondsSinceEpoch}_$fileName');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    debugPrint('🟢 [ChatAudioFileService] Upload SUCCESS');

    // ─────────────────────────────────────────────
    // 2️⃣ WRITE FIRESTORE MESSAGE (AUTHORITATIVE)
    // ─────────────────────────────────────────────
    final payload = {
      'type': 'audio',
      'path': downloadUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'senderId': user.uid,
      'createdAt': now,
      'status': 'sent', // 🔑 CRITICAL
    };

    debugPrint(
      '🎧🎧🎧 [ChatAudioFileService] FIRESTORE PAYLOAD → $payload',
    );

    await messagesRef.add(payload);

    debugPrint('🟢 [ChatAudioFileService] Firestore document written');

    // ─────────────────────────────────────────────
    // 3️⃣ UPDATE CONVERSATION META
    // ─────────────────────────────────────────────
    final messageService = ChatMessageService(conversationId);

    await messageService.updateAfterAudioFileSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint('🟢 [ChatAudioFileService] Conversation meta updated');
  }
}
