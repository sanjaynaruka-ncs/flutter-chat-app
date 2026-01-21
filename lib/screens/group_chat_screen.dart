import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tokwalker/widgets/group_chat_app_bar.dart';
import 'package:tokwalker/widgets/chat_message_list.dart';
import 'package:tokwalker/widgets/chat_input_bar.dart';
import 'package:tokwalker/widgets/chat_message_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  @override
  void initState() {
    super.initState();
    _markGroupAsRead();
  }

  /// ✅ Clears unread for CURRENT user only (group-safe)
  Future<void> _markGroupAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'unread.${user.uid}': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GroupChatAppBar(
        title: widget.groupName,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Messages (UI placeholder)
          Expanded(
            child: ChatMessageList(
              messages: const [
                ChatBubbleUi(
                  text: 'Hello everyone',
                  isMe: false,
                  time: '',
                  status: MessageStatus.sent,
                ),
                ChatBubbleUi(
                  text: 'Hi 👋',
                  isMe: true,
                  time: '',
                  status: MessageStatus.sent,
                ),
              ],
            ),
          ),

          // Input bar
          ChatInputBar(
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  /// 🔹 TEMP: UI-only handler (logic comes later)
  void _handleSendMessage(String text) {
    // Intentionally left blank
    // Group send logic will be wired later
  }
}
