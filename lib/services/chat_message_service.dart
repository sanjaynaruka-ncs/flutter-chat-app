import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageService {
  final String conversationId;

  ChatMessageService(this.conversationId);

  // ─────────────────────────────────────────────
  // 📡 MESSAGE STREAMS (UNCHANGED)
  // ─────────────────────────────────────────────

  Stream<QuerySnapshot> messagesStream() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Stream<QuerySnapshot> messagesStreamAfter(Timestamp clearedAt) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('createdAt', isGreaterThan: clearedAt)
        .orderBy('createdAt')
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // 💬 TEXT MESSAGE
  // ─────────────────────────────────────────────
  Future<void> sendTextMessage({
    required String text,
    required String senderId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    await convoRef.collection('messages').add({
      'type': 'text',
      'text': trimmed,
      'senderId': senderId,
      'createdAt': now,
      'status': 'sent',
    });

    await _updateConversationMeta(
      senderId: senderId,
      now: now,
      lastMessage: trimmed,
    );
  }

  // ─────────────────────────────────────────────
  // ✅ DELIVERY ACK — FIXED & SAFE
  // ─────────────────────────────────────────────
  Future<void> markMessagesAsDelivered({
    required String receiverId,
  }) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final snap = await messagesRef
        .where('status', isEqualTo: 'sent')
        .get();

    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    // Debug Start//
    print('🌟🌟 DELIVERED SNAP COUNT: ${snap.docs.length}');
    //Debug End //

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Debug Start//
      print('🌟🌟 TRY UPDATE DOC: ${doc.id} | sender=${data['senderId']}');
        //Debug End //

      batch.update(doc.reference, {
        'status': 'delivered',
        'deliveredAt': Timestamp.now(),
      });
    }

    await batch.commit();
    print('🌟🌟 DELIVERED BATCH COMMITTED');
  }

  // ─────────────────────────────────────────────
  // 👁️ READ ACK — FIXED & SAFE
  // ─────────────────────────────────────────────
  Future<void> markMessagesAsRead({
  required String readerId,
    }) async {
      print('🟦 READ START | reader=$readerId');

      final messagesRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

      // 🔑 CRITICAL FIX:
      // Only messages:
      // - NOT sent by me
      // - ALREADY delivered
      final snap = await messagesRef
          .where('senderId', isNotEqualTo: readerId)
          .where('status', isEqualTo: 'delivered')
          .get();

      print('🟦 READ QUERY COUNT = ${snap.docs.length}');

      // 🛑 HARD STOP — prevents loops
      if (snap.docs.isEmpty) {
        print('🟦 READ SKIPPED — nothing to mark');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🟦 READ TRY doc=${doc.id} sender=${data['senderId']}');

        batch.update(doc.reference, {
          'status': 'read',
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      print('🟦 READ COMMIT DONE');

      // ✅ Unread = 0 for this user (idempotent, safe)
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set(
        {
          'unread.$readerId': 0,
        },
        SetOptions(merge: true),
      );

      print('🟦 UNREAD RESET DONE');
    }

  // ─────────────────────────────────────────────
  // 🖼 IMAGE
  // ─────────────────────────────────────────────
  Future<void> updateAfterImageSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '📸 Photo',
      );

  // ─────────────────────────────────────────────
  // 🎥 VIDEO
  // ─────────────────────────────────────────────
  Future<void> updateAfterVideoSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '🎥 Video',
      );

  // ─────────────────────────────────────────────
  // 🔊 AUDIO (RECORDED / FILE)
  // ─────────────────────────────────────────────
  Future<void> updateAfterAudioSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '🎧 Audio',
      );

  Future<void> updateAfterAudioFileSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '🎧 Audio',
      );

  // ─────────────────────────────────────────────
  // 📄 DOCUMENT
  // ─────────────────────────────────────────────
  Future<void> updateAfterDocumentSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '📄 Document',
      );

  // ─────────────────────────────────────────────
  // 👤 CONTACT
  // ─────────────────────────────────────────────
  Future<void> updateAfterContactSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '👤 Contact',
      );

  // ─────────────────────────────────────────────
  // 📍 LOCATION
  // ─────────────────────────────────────────────
  Future<void> updateAfterLocationSend({
    required String senderId,
    required Timestamp createdAt,
  }) =>
      _updateConversationMeta(
        senderId: senderId,
        now: createdAt,
        lastMessage: '📍 Location',
      );

  // ─────────────────────────────────────────────
  // 🔑 META UPDATE (UNCHANGED & SAFE)
  // ─────────────────────────────────────────────
  Future<void> _updateConversationMeta({
    required String senderId,
    required Timestamp now,
    required String lastMessage,
  }) async {
    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final snap = await convoRef.get();
    final data = snap.data() as Map<String, dynamic>?;

    if (data == null) return;

    final Timestamp? currentUpdatedAt = data['updatedAt'];
    if (currentUpdatedAt != null &&
        currentUpdatedAt.compareTo(now) > 0) {
      return;
    }

    final List<String> participants =
        List<String>.from(data['participants'] ?? []);

    final Map<String, dynamic> unread = {};
    for (final uid in participants) {
      unread['unread.$uid'] =
          uid == senderId ? 0 : FieldValue.increment(1);
    }

    final Map<String, dynamic> restore = {};
    for (final uid in participants) {
      if (uid == senderId) continue;

      final bool receiverHadDeleted =
          (data['deletedAt'] is Map &&
              data['deletedAt'][uid] != null) ||
          data['deletedAt.$uid'] != null;

      if (receiverHadDeleted) {
        restore['deletedAt.$uid'] = FieldValue.delete();
      }
    }

    await convoRef.set({
      'lastMessage': lastMessage,
      'updatedAt': now,
      ...unread,
      ...restore,
    }, SetOptions(merge: true));
  }
}
