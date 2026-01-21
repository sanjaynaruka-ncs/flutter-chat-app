import 'package:flutter/material.dart';

/// 🔍 Chat search state controller (NO UI)
/// Single-responsibility: search mode + query handling
class ChatSearchController {
  bool _isSearchMode = false;

  final TextEditingController controller = TextEditingController();

  bool get isSearchMode => _isSearchMode;

  /// Enter search mode
  void enter() {
    _isSearchMode = true;
    controller.clear();
  }

  /// Exit search mode
  void exit() {
    _isSearchMode = false;
    controller.clear();
  }

  /// Dispose resources
  void dispose() {
    controller.dispose();
  }

  /// Match helper for message text
  bool matchesQuery(String text) {
    if (!_isSearchMode) return true;

    final query = controller.text.trim().toLowerCase();
    if (query.isEmpty) return true;

    return text.toLowerCase().contains(query);
  }
}
