import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// 👤 ChatContactActionController
///
/// ✅ LOGIC ONLY
/// ❌ NO UI
/// ❌ NO Navigator
/// ❌ NO BuildContext
///
/// UI decides navigation based on returned values
class ChatContactActionController {
  // ─────────────────────────────────────────────
  // 🔍 FIND USER BY PHONE
  // ─────────────────────────────────────────────
  Future<String?> findUserByPhone(String phone) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      return snap.docs.first.id; // userId
    } catch (e) {
      debugPrint('🔴 [ContactAction] findUserByPhone failed: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 💬 MESSAGE OR INVITE (LOGIC ONLY)
  // ─────────────────────────────────────────────
  Future<ContactMessageResult> messageOrInvite({
    required String phone,
  }) async {
    debugPrint('💬 [ContactAction] messageOrInvite | phone=$phone');

    final userId = await findUserByPhone(phone);

    if (userId != null) {
      debugPrint('🟢 [ContactAction] User exists on app');
      return ContactMessageResult.openChat(userId);
    }

    debugPrint('🟡 [ContactAction] User not on app → invite via SMS');

    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {
        'body':
            'Hey! I am using TokWalker chat app. Join me here 👇\nhttps://tokwalker.app',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    return const ContactMessageResult.invited();
  }

  // ─────────────────────────────────────────────
  // ➕ ADD TO CONTACTS (PHASE-SAFE STUB)
  // ─────────────────────────────────────────────
  Future<void> addToContacts({
    required String name,
    required String phone,
  }) async {
    debugPrint(
      '👤 [ContactAction] addToContacts | name=$name | phone=$phone',
    );

    // Phase-3:
    // UI will open native "Add Contact" screen
    // with prefilled name & phone
  }

  // ─────────────────────────────────────────────
  // 🔎 SIMPLE BOOL CHECK (REUSED)
  // ─────────────────────────────────────────────
  Future<bool> isUserOnApp(String phone) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// ─────────────────────────────────────────────
/// 📦 RESULT MODEL (UI DECIDES WHAT TO DO)
/// ─────────────────────────────────────────────
class ContactMessageResult {
  final String? userId;
  final bool invited;

  const ContactMessageResult._({
    required this.userId,
    required this.invited,
  });

  factory ContactMessageResult.openChat(String userId) {
    return ContactMessageResult._(
      userId: userId,
      invited: false,
    );
  }

  const factory ContactMessageResult.invited() =
      _InvitedResult;
}

class _InvitedResult extends ContactMessageResult {
  const _InvitedResult()
      : super._(
          userId: null,
          invited: true,
        );

Future<void> openChatIfExists({
  required BuildContext context,
  required String phone,
}) async {
  debugPrint('📨 [ContactAction] Open SMS invite → $phone');

  final uri = Uri(
    scheme: 'sms',
    path: phone,
    queryParameters: {
      'body':
          'Hey! I am using TokWalker chat app. Join me here 👇\nhttps://tokwalker.app',
    },
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint('🔴 SMS app not available');
  }
}

}
