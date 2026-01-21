import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class ChatVideoService {
  final String conversationId;

  ChatVideoService(this.conversationId);

  Future<void> sendVideo({
    required String localVideoPath,
    required String clientId,
  }) async {
    debugPrint(
      '🎥 [ChatVideoService] sendVideo | path=$localVideoPath | clientId=$clientId',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔴 [ChatVideoService] ABORT user=null');
      return;
    }

    final videoFile = File(localVideoPath);
    if (!videoFile.existsSync()) {
      debugPrint('🔴 [ChatVideoService] Video file missing');
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // ─────────────────────────────────────────────
    // 1️⃣ UPLOAD VIDEO
    // ─────────────────────────────────────────────
    final videoRef = FirebaseStorage.instance
        .ref()
        .child('chat_videos')
        .child(conversationId)
        .child('${now.millisecondsSinceEpoch}_${user.uid}.mp4');

    await videoRef.putFile(videoFile);
    final videoUrl = await videoRef.getDownloadURL();

    debugPrint('🎥 Video uploaded');

    // ─────────────────────────────────────────────
    // 2️⃣ GENERATE THUMBNAIL (LOCAL)
    // ─────────────────────────────────────────────
    final tempDir = await getTemporaryDirectory();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: localVideoPath,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );

    String? thumbnailUrl;

    if (thumbPath != null) {
      final thumbFile = File(thumbPath);

      final thumbRef = FirebaseStorage.instance
          .ref()
          .child('chat_video_thumbnails')
          .child(conversationId)
          .child('${now.millisecondsSinceEpoch}_${user.uid}.jpg');

      await thumbRef.putFile(thumbFile);
      thumbnailUrl = await thumbRef.getDownloadURL();

      debugPrint('🖼️ Thumbnail uploaded');
    } else {
      debugPrint('⚠️ Thumbnail generation failed');
    }

    // ─────────────────────────────────────────────
    // 3️⃣ WRITE MESSAGE (VIDEO + STATUS)
    // ─────────────────────────────────────────────
    await messagesRef.add({
      'type': 'video',
      'path': videoUrl,
      'thumbnail': thumbnailUrl, // optional
      'senderId': user.uid,
      'clientId': clientId,
      'createdAt': now,
      'status': 'sent', // ✅ REQUIRED FOR TICKS
    });

    debugPrint('📄 Firestore video message written');

    // ─────────────────────────────────────────────
    // 4️⃣ META UPDATE (UNCHANGED)
    // ─────────────────────────────────────────────
    final convoSnap = await convoRef.get();
    final data = convoSnap.data();
    if (data == null) return;

    final List<String> participants =
        List<String>.from(data['participants'] ?? []);

    final Map<String, dynamic> unread = {};
    for (final uid in participants) {
      unread['unread.$uid'] =
          uid == user.uid ? 0 : FieldValue.increment(1);
    }

    final Map<String, dynamic> restore = {};
    for (final uid in participants) {
      restore['deletedAt.$uid'] = FieldValue.delete();
    }

    await convoRef.set({
      'lastMessage': '🎥 Video',
      'updatedAt': now,
      ...unread,
      ...restore,
    }, SetOptions(merge: true));

    debugPrint('📌 Conversation meta updated');
  }
}
