import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactResolver {
  static final Map<String, String> _phoneToName = {};

  static Future<void> loadContacts() async {
    print('🔥 ContactResolver.loadContacts() CALLED');

    final status = await Permission.contacts.status;

    if (!status.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) {
        print('❌ Contacts permission NOT granted');
        return;
      }
    }

    print('✅ Contacts permission GRANTED');

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    _phoneToName.clear();

    for (final contact in contacts) {
      final name = contact.displayName;

      for (final phone in contact.phones) {
        final normalized = _normalize(phone.number);
        if (normalized.isNotEmpty) {
          _phoneToName[normalized] = name;
        }
      }
    }

    print('📒 Total contacts loaded: ${_phoneToName.length}');
  }

  static String resolve(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    final normalized = _normalize(phoneNumber);
    return _phoneToName[normalized] ?? phoneNumber;
  }

  static String _normalize(String number) {
    var digits = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return digits;
  }
}
