import 'package:flutter/material.dart';

/// 🔹 Supported chat themes (per user, per chat)
enum ChatThemeType {
  defaultTheme,
  dark,
  ocean,
  forest,
  sunset,
}

/// 🔹 Resolved theme colors used by message bubbles & background
class ChatTheme {
  final Color myMessageBg;
  final Color otherMessageBg;
  final Color myTextColor;
  final Color otherTextColor;
  final Color chatBackground;

  const ChatTheme({
    required this.myMessageBg,
    required this.otherMessageBg,
    required this.myTextColor,
    required this.otherTextColor,
    required this.chatBackground,
  });
}

/// 🔹 Theme registry (single source of truth)
class ChatThemeRegistry {
  static const ChatTheme defaultTheme = ChatTheme(
    myMessageBg: Color(0xFFDCF8C6), // WhatsApp-like
    otherMessageBg: Colors.white,
    myTextColor: Colors.black,
    otherTextColor: Colors.black,
    chatBackground: Color(0xFFEFEFEF),
  );

  static const ChatTheme dark = ChatTheme(
    myMessageBg: Color(0xFF054640),
    otherMessageBg: Color(0xFF1F2C34),
    myTextColor: Colors.white,
    otherTextColor: Colors.white,
    chatBackground: Color(0xFF0B141A),
  );

  static const ChatTheme ocean = ChatTheme(
    myMessageBg: Color(0xFFB3E5FC),
    otherMessageBg: Colors.white,
    myTextColor: Colors.black,
    otherTextColor: Colors.black,
    chatBackground: Color(0xFFE1F5FE),
  );

  static const ChatTheme forest = ChatTheme(
    myMessageBg: Color(0xFFC8E6C9),
    otherMessageBg: Colors.white,
    myTextColor: Colors.black,
    otherTextColor: Colors.black,
    chatBackground: Color(0xFFE8F5E9),
  );

  static const ChatTheme sunset = ChatTheme(
    myMessageBg: Color(0xFFFFCCBC),
    otherMessageBg: Colors.white,
    myTextColor: Colors.black,
    otherTextColor: Colors.black,
    chatBackground: Color(0xFFFFF3E0),
  );

  /// 🔹 Resolver
  static ChatTheme resolve(ChatThemeType type) {
    switch (type) {
      case ChatThemeType.dark:
        return dark;
      case ChatThemeType.ocean:
        return ocean;
      case ChatThemeType.forest:
        return forest;
      case ChatThemeType.sunset:
        return sunset;
      case ChatThemeType.defaultTheme:
      default:
        return defaultTheme;
    }
  }

  /// 🔹 Firestore string ↔ enum helpers
  static ChatThemeType fromString(String? value) {
    switch (value) {
      case 'dark':
        return ChatThemeType.dark;
      case 'ocean':
        return ChatThemeType.ocean;
      case 'forest':
        return ChatThemeType.forest;
      case 'sunset':
        return ChatThemeType.sunset;
      case 'default':
      default:
        return ChatThemeType.defaultTheme;
    }
  }

  static String toStringValue(ChatThemeType type) {
    switch (type) {
      case ChatThemeType.dark:
        return 'dark';
      case ChatThemeType.ocean:
        return 'ocean';
      case ChatThemeType.forest:
        return 'forest';
      case ChatThemeType.sunset:
        return 'sunset';
      case ChatThemeType.defaultTheme:
      default:
        return 'default';
    }
  }
}
