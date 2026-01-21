import 'package:flutter/material.dart';

class ChatSelectionController extends ChangeNotifier {
  String? _selectedConversationId;

  String? get selectedId => _selectedConversationId;
  bool get hasSelection => _selectedConversationId != null;

  void select(String conversationId) {
    _selectedConversationId = conversationId;
    notifyListeners();
  }

  void clear() {
    _selectedConversationId = null;
    notifyListeners();
  }
}
