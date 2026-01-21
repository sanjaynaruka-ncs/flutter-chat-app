import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Handles Block / Unblock lifecycle (NO UI)
/// Single source of truth with optimistic local override
class ChatBlockManager {
  bool? _localBlocked;

  /// Read server block state from conversation document
  bool getServerBlocked({
    required Map<String, dynamic>? conversationData,
    required String myUid,
  }) {
    if (conversationData == null) return false;

    final blockedMap = conversationData['blocked'];
    if (blockedMap is Map && blockedMap[myUid] == true) {
      return true;
    }

    final flat = conversationData['blocked.$myUid'];
    if (flat == true) return true;

    return false;
  }

  /// Resolve effective blocked state (local wins immediately)
  bool resolveBlocked({
    required bool serverBlocked,
  }) {
    return _localBlocked ?? serverBlocked;
  }

  /// Sync local override once server reflects the change
  void syncWithServer({
    required bool serverBlocked,
  }) {
    if (_localBlocked != null && _localBlocked == serverBlocked) {
      _localBlocked = null;
    }
  }

  /// Optimistic local block
  void markBlocked() {
    _localBlocked = true;
  }

  /// Optimistic local unblock
  void markUnblocked() {
    _localBlocked = false;
  }

  /// Persist block to Firestore
  static Future<void> block({
    required String conversationId,
    required String myUid,
  }) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .set(
      {
        'blocked.$myUid': true,
      },
      SetOptions(merge: true),
    );
  }

  /// Persist unblock to Firestore
  static Future<void> unblock({
    required String conversationId,
    required String myUid,
  }) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .set(
      {
        'blocked.$myUid': false,
      },
      SetOptions(merge: true),
    );
  }

  /// Dispose local state (safety)
  void dispose() {
    _localBlocked = null;
  }
}
