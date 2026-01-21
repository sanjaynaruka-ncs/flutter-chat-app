import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tokwalker/themes/chat_theme.dart';

class ChatThemeService {
  /// 🔹 Save theme for current user in a conversation
  static Future<void> setTheme({
    required String conversationId,
    required String myUid,
    required ChatThemeType theme,
  }) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .set({
      'theme.$myUid':
          ChatThemeRegistry.toStringValue(theme),
    }, SetOptions(merge: true));
  }

  /// 🔹 Read theme string from conversation document
  static ChatThemeType resolveThemeFromConversation(
    Map<String, dynamic>? conversationData,
    String myUid,
  ) {
    if (conversationData == null) {
      return ChatThemeType.defaultTheme;
    }

    final themeMap = conversationData['theme'];
    if (themeMap is Map &&
        themeMap[myUid] is String) {
      return ChatThemeRegistry.fromString(
          themeMap[myUid]);
    }

    final flatTheme = conversationData['theme.$myUid'];
    if (flatTheme is String) {
      return ChatThemeRegistry.fromString(flatTheme);
    }

    return ChatThemeType.defaultTheme;
  }
}
