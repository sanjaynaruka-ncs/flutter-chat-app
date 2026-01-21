import 'package:flutter/material.dart';

/// 🙂 Emoji picker state controller
/// Single responsibility:
/// - Toggle emoji panel
/// - Coordinate with keyboard focus
class ChatEmojiController {
  bool _isEmojiVisible = false;

  bool get isEmojiVisible => _isEmojiVisible;

  /// Toggle emoji panel
  void toggle({
    required FocusNode focusNode,
  }) {
    if (_isEmojiVisible) {
      _isEmojiVisible = false;
      focusNode.requestFocus();
    } else {
      _isEmojiVisible = true;
      focusNode.unfocus();
    }
  }

  /// Force close emoji panel
  void close({
    required FocusNode focusNode,
  }) {
    if (_isEmojiVisible) {
      _isEmojiVisible = false;
      focusNode.requestFocus();
    }
  }
}
