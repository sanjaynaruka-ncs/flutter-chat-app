import 'package:flutter_contacts/flutter_contacts.dart';

class ContactHelper {
  static Map<String, String> _phoneToName = {};

  static Future<void> loadContacts() async {
    if (!await FlutterContacts.requestPermission()) return;

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );

    _phoneToName.clear();

    for (final c in contacts) {
      if (c.phones.isEmpty) continue;

      final name = c.displayName;
      for (final p in c.phones) {
        final normalized = _normalize(p.number);
        _phoneToName[normalized] = name;
      }
    }
  }

  static String resolveName(String phone) {
    return _phoneToName[_normalize(phone)] ?? phone;
  }

  static String _normalize(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
