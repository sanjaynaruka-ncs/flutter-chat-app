import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

/// 🖼️ ChatImageService
/// ------------------------------------------------------------
/// SINGLE RESPONSIBILITY:
/// - Upload ANY image file (camera OR gallery) to Firebase Storage
/// - Write IMAGE message document to Firestore
/// - Update conversation meta (lastMessage = 📸 Photo)
///
/// IMPORTANT:
/// - Camera images and gallery images are treated IDENTICALLY
/// - Source does NOT matter — only local file path
///
/// ❌ NO UI
/// ❌ NO pickers
/// ❌ NO optimistic logic
///
/// ✅ Sender safe
/// ✅ Receiver safe
/// ✅ Tick-safe (status = sent at creation)
/// ------------------------------------------------------------
class ChatImageService {
  final String conversationId;

  ChatImageService(this.conversationId);

  /// 🔥 SEND IMAGE MESSAGE
  ///
  /// [localImagePath] can come from:
  /// - Camera capture
  /// - Gallery picker
  ///
  /// Both flows are intentionally unified here.
  Future<void> sendImage({
    required String localImagePath,
  }) async {
    debugPrint(
      '🟣 [ChatImageService] sendImage START | localPath=$localImagePath',
    );

    // ─────────────────────────────────────────────
    // 0️⃣ AUTH GUARD
    // ─────────────────────────────────────────────
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        '🔴 [ChatImageService] ABORT | currentUser is NULL',
      );
      return;
    }

    // ─────────────────────────────────────────────
    // 1️⃣ FILE GUARD (CAMERA / GALLERY BOTH)
    // ─────────────────────────────────────────────
    final file = File(localImagePath);
    if (!file.existsSync()) {
      debugPrint(
        '🔴 [ChatImageService] ABORT | file does NOT exist → $localImagePath',
      );
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // ─────────────────────────────────────────────
    // 2️⃣ UPLOAD IMAGE TO FIREBASE STORAGE
    // ─────────────────────────────────────────────
    debugPrint(
      '🟣 [ChatImageService] Uploading image to Firebase Storage…',
    );

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(conversationId)
        .child('${now.millisecondsSinceEpoch}_${user.uid}.jpg');

    await storageRef.putFile(file);

    final String downloadUrl = await storageRef.getDownloadURL();

    debugPrint(
      '🟣 [ChatImageService] Upload SUCCESS | url=$downloadUrl',
    );

    // ─────────────────────────────────────────────
    // 3️⃣ WRITE IMAGE MESSAGE (STATUS AT CREATION)
    // ─────────────────────────────────────────────
    await messagesRef.add({
      'type': 'image',
      'path': downloadUrl,
      'senderId': user.uid,
      'createdAt': now,
      'status': 'sent', // ✅ REQUIRED FOR TICKS
    });

    debugPrint(
      '🟣 [ChatImageService] Firestore IMAGE message written',
    );

    // ─────────────────────────────────────────────
    // 4️⃣ UPDATE CONVERSATION META (📸 Photo)
    // ─────────────────────────────────────────────
    final messageService = ChatMessageService(conversationId);

    await messageService.updateAfterImageSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint(
      '🟢 [ChatImageService] Conversation meta updated (IMAGE)',
    );
  }
}
