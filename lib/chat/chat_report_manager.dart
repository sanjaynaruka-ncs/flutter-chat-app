import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚩 Handles Chat Report lifecycle (NO CHAT UI)
/// Single source of truth for reporting logic
class ChatReportManager {
  /// 🔴 Entry point used by ChatMenuController / ChatScreen
  static Future<void> reportChat({
    required BuildContext context,
    required String conversationId,
    required String reporterUid,
  }) async {
    final confirm = await _showConfirmDialog(context);
    if (confirm != true) return;

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final convoSnap = await convoRef.get();
    final data = convoSnap.data();
    if (data == null) return;

    final participants =
        List<String>.from(data['participants'] ?? []);

    final reportedUid = participants.firstWhere(
      (p) => p != reporterUid,
      orElse: () => '',
    );

    if (reportedUid.isEmpty) return;

    // 🔹 Fetch last 5 messages (evidence)
    final msgSnap = await convoRef
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final messages = msgSnap.docs
        .map((d) => d.data())
        .toList();

    await FirebaseFirestore.instance.collection('reports').add({
      'conversationId': conversationId,
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'messages': messages,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat reported'),
        ),
      );
    }
  }

  // ───────────────── PRIVATE UI ─────────────────

  static Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report chat'),
        content: const Text(
          'The last few messages from this chat will be sent to TokWalker for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
