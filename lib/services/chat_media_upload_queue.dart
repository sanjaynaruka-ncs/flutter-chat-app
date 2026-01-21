import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_image_service.dart';
import 'chat_video_service.dart';
import 'chat_message_service.dart';

/// 🚚 ChatMediaUploadQueue
/// SINGLE RESPONSIBILITY:
/// - Own media uploads (image / video)
/// - Survive UI dispose
/// - Guarantee Firestore write + meta update
///
/// ❌ NO UI
/// ❌ NO BuildContext
/// ❌ NO widget lifecycle
///
/// 🔑 Singleton (process-wide)
class ChatMediaUploadQueue {
  ChatMediaUploadQueue._internal();

  static final ChatMediaUploadQueue _instance =
      ChatMediaUploadQueue._internal();

  factory ChatMediaUploadQueue() => _instance;

  /// 🔄 In-memory job queue
  final List<_MediaJob> _queue = [];

  bool _isProcessing = false;

  // ─────────────────────────────────────────────
  // 🖼️ ENQUEUE IMAGE
  // ─────────────────────────────────────────────
  void enqueueImage({
    required String conversationId,
    required String localPath,
  }) {
    debugPrint(
      '🚦 [ChatMediaUploadQueue] ENQUEUE IMAGE | convo=$conversationId | path=$localPath',
    );

    _queue.add(
      _MediaJob.image(
        conversationId: conversationId,
        localPath: localPath,
      ),
    );

    _processQueue();
  }

  // ─────────────────────────────────────────────
  // 🎥 ENQUEUE VIDEO
  // ─────────────────────────────────────────────
  void enqueueVideo({
    required String conversationId,
    required String localPath,
    required String clientId,
  }) {
    debugPrint(
      '🚦 [ChatMediaUploadQueue] ENQUEUE VIDEO | convo=$conversationId | clientId=$clientId | path=$localPath',
    );

    _queue.add(
      _MediaJob.video(
        conversationId: conversationId,
        localPath: localPath,
        clientId: clientId,
      ),
    );

    _processQueue();
  }

  // ─────────────────────────────────────────────
  // 🔁 PROCESS QUEUE (SERIAL, SAFE)
  // ─────────────────────────────────────────────
  Future<void> _processQueue() async {
    if (_isProcessing) {
      debugPrint('⏸️ [ChatMediaUploadQueue] already processing, skip');
      return;
    }

    if (_queue.isEmpty) {
      debugPrint('📭 [ChatMediaUploadQueue] queue empty, nothing to do');
      return;
    }

    _isProcessing = true;
    debugPrint(
      '▶️ [ChatMediaUploadQueue] PROCESSING START | jobs=${_queue.length}',
    );

    while (_queue.isNotEmpty) {
      final job = _queue.first;

      try {
        debugPrint(
          '🚀 [ChatMediaUploadQueue] EXECUTE job | type=${job.type} | convo=${job.conversationId}',
        );

        await _execute(job);

        _queue.removeAt(0);

        debugPrint(
          '✅ [ChatMediaUploadQueue] JOB DONE | remaining=${_queue.length}',
        );
      } catch (e, st) {
        debugPrint(
          '🔴 [ChatMediaUploadQueue] JOB FAILED — will retry later\n$e\n$st',
        );
        break; // stop loop, retry later
      }
    }

    _isProcessing = false;
    debugPrint('⏹️ [ChatMediaUploadQueue] PROCESSING END');
  }

  // ─────────────────────────────────────────────
  // 🚀 EXECUTE SINGLE JOB
  // ─────────────────────────────────────────────
  Future<void> _execute(_MediaJob job) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        '🔴 [ChatMediaUploadQueue] ABORT: user not authenticated',
      );
      throw Exception('User not authenticated');
    }

    debugPrint(
      '▶️ [ChatMediaUploadQueue] START ${job.type} upload | clientId=${job.clientId}',
    );

    if (job.type == _MediaType.image) {
      final imageService = ChatImageService(job.conversationId);
      final messageService = ChatMessageService(job.conversationId);

      await imageService.sendImage(
        localImagePath: job.localPath!,
      );

      await messageService.updateAfterImageSend(
        senderId: user.uid,
        createdAt: job.createdAt,
      );
    }

    if (job.type == _MediaType.video) {
      final videoService = ChatVideoService(job.conversationId);
      final messageService = ChatMessageService(job.conversationId);

      await videoService.sendVideo(
        localVideoPath: job.localPath!,
        clientId: job.clientId!,
      );

      await messageService.updateAfterVideoSend(
        senderId: user.uid,
        createdAt: job.createdAt,
      );
    }

    debugPrint(
      '✅ [ChatMediaUploadQueue] FINISH ${job.type} | clientId=${job.clientId}',
    );
  }
}

// ─────────────────────────────────────────────
// 🔒 INTERNAL MODELS (PRIVATE)
// ─────────────────────────────────────────────

enum _MediaType { image, video }

class _MediaJob {
  final _MediaType type;
  final String conversationId;
  final String? localPath;
  final String? clientId;
  final Timestamp createdAt;

  _MediaJob.image({
    required this.conversationId,
    required this.localPath,
  })  : type = _MediaType.image,
        clientId = null,
        createdAt = Timestamp.now();

  _MediaJob.video({
    required this.conversationId,
    required this.localPath,
    required this.clientId,
  })  : type = _MediaType.video,
        createdAt = Timestamp.now();
}
