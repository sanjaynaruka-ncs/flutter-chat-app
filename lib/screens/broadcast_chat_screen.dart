import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_message_service.dart';
import '../widgets/chat_input_bar.dart';
import 'broadcast_recipients_screen.dart';

class BroadcastChatScreen extends StatefulWidget {
  final String broadcastId;
  final String name;
  final int membersCount;

  const BroadcastChatScreen({
    super.key,
    required this.broadcastId,
    required this.name,
    required this.membersCount,
  });

  @override
  State<BroadcastChatScreen> createState() =>
      _BroadcastChatScreenState();
}

class _BroadcastChatScreenState
    extends State<BroadcastChatScreen> {
  bool _sending = false;
  late int _membersCount;

  /// Sender-only visible messages
  final List<String> _sentMessages = [];

  @override
  void initState() {
    super.initState();
    _membersCount = widget.membersCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _openRecipients,
          child: Text(
            '${widget.name} | Tap to edit list',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _sentMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Messages sent via broadcast are delivered '
                        'individually to each recipient.\n\n'
                        'Replies will come as personal chats.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _sentMessages.length,
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            _sentMessages[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          ChatInputBar(
            onSend: _handleSendBroadcast,
          ),
        ],
      ),
    );
  }

  Future<void> _openRecipients() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => BroadcastRecipientsScreen(
          broadcastId: widget.broadcastId,
        ),
      ),
    );

    if (result == null) return;

    await FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(widget.broadcastId)
        .update({
      'members': result,
    });

    setState(() {
      _membersCount = result.length;
    });
  }

  Future<void> _handleSendBroadcast(String text) async {
    if (_sending) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _sentMessages.add(trimmed);
      _sending = true;
    });

    try {
      final broadcastDoc = await FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(widget.broadcastId)
          .get();

      final data = broadcastDoc.data();
      if (data == null) return;

      final List<String> members =
          List<String>.from(data['members'] ?? []);

      for (final receiverUid in members) {
        final convoId =
            _conversationIdFor(user.uid, receiverUid);

        await _ensureConversationExists(
          convoId: convoId,
          senderUid: user.uid,
          receiverUid: receiverUid,
        );

        final service = ChatMessageService(convoId);

        await service.sendTextMessage(
          text: trimmed,
          senderId: user.uid,
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  String _conversationIdFor(String a, String b) {
    return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
  }

  Future<void> _ensureConversationExists({
    required String convoId,
    required String senderUid,
    required String receiverUid,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('conversations')
        .doc(convoId);

    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'participants': [senderUid, receiverUid],
      'isGroup': false,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'unread': {
        senderUid: 0,
        receiverUid: 0,
      },
    });
  }
}
