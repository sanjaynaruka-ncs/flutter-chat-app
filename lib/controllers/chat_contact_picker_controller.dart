import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// 👤 ChatContactPickerController
///
/// RESPONSIBILITY:
/// - Open device contact picker
/// - Return selected contact(s) in safe format
///
/// ❌ No UI
/// ❌ No Firestore
/// ❌ No widgets
class ChatContactPickerController {
  /// Pick contacts from device
  Future<List<PickedContact>> pickContacts() async {
    try {
      debugPrint('👤 [ContactPicker] Requesting permission');

      if (!await FlutterContacts.requestPermission()) {
        debugPrint('🔴 [ContactPicker] Permission denied');
        return [];
      }

      debugPrint('👤 [ContactPicker] Opening contact picker');

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      return contacts
          .where((c) => c.phones.isNotEmpty)
          .map(
            (c) => PickedContact(
              name: c.displayName,
              phone: c.phones.first.number,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('🔴 [ContactPicker] Error → $e');
      return [];
    }
  }
}

/// ✅ SAFE CONTACT MODEL (UI + FIRESTORE FRIENDLY)
class PickedContact {
  final String name;
  final String phone;

  PickedContact({
    required this.name,
    required this.phone,
  });
}
