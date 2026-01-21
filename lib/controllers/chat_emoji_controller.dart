import 'package:flutter/foundation.dart';

/// 😊 ChatEmojiController
/// UI-agnostic state holder
///
/// Responsibilities:
/// - Track emoji panel visibility
/// - Toggle emoji <-> keyboard mode
///
/// ❌ No UI
/// ❌ No context
/// ❌ No TextField access
class ChatEmojiController extends ChangeNotifier {
  bool _isEmojiVisible = false;

  bool get isEmojiVisible => _isEmojiVisible;

  void showEmoji() {
    if (_isEmojiVisible) return;
    _isEmojiVisible = true;
    notifyListeners();
  }

  void hideEmoji() {
    if (!_isEmojiVisible) return;
    _isEmojiVisible = false;
    notifyListeners();
  }

  void toggle() {
    _isEmojiVisible = !_isEmojiVisible;
    notifyListeners();
  }
}
