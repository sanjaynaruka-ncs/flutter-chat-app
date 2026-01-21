import 'package:flutter/material.dart';

import 'chat_clear_manager.dart';
import 'chat_block_manager.dart';
import 'chat_report_manager.dart';

class ChatMenuController {
  final BuildContext context;
  final String conversationId;
  final String myUid;

  ChatMenuController({
    required this.context,
    required this.conversationId,
    required this.myUid,
  });

  // 🔍 SEARCH (UI-controlled, DO NOT pop)
  void search(VoidCallback enterSearchMode) {
    enterSearchMode();
  }

  // 🧹 CLEAR CHAT (per-user)
  Future<void> clearChat() async {
    return ChatClearManager.clearChat(
      conversationId: conversationId,
      myUid: myUid,
    );
  }

  // 🚫 BLOCK USER (per-user)
  Future<void> block() async {
    return ChatBlockManager.block(
      conversationId: conversationId,
      myUid: myUid,
    );
  }

  // ✅ UNBLOCK USER
  Future<void> unblock() async {
    return ChatBlockManager.unblock(
      conversationId: conversationId,
      myUid: myUid,
    );
  }

  // 🚩 REPORT CHAT
  Future<void> report() async {
    return ChatReportManager.reportChat(
      context: context,
      conversationId: conversationId,
      reporterUid: myUid,
    );
  }

  // 👥 CREATE NEW GROUP (navigation handled elsewhere)
  void newGroup(VoidCallback onCreateGroup) {
    onCreateGroup();
  }
}
