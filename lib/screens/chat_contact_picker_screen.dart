import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ChatContactPickerScreen extends StatefulWidget {
  const ChatContactPickerScreen({super.key});

  @override
  State<ChatContactPickerScreen> createState() =>
      _ChatContactPickerScreenState();
}

class _ChatContactPickerScreenState
    extends State<ChatContactPickerScreen> {
  List<Contact> _contacts = [];
  final Set<Contact> _selected = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: false,
    );

    setState(() {
      _contacts =
          contacts.where((c) => c.phones.isNotEmpty).toList();
      _loading = false;
    });
  }

  void _toggle(Contact contact) {
    setState(() {
      if (_selected.contains(contact)) {
        _selected.remove(contact);
      } else {
        _selected.add(contact);
      }
    });
  }

  void _send() {
    final result = _selected.map((c) {
      return {
        'name': c.displayName,
        'phone': c.phones.first.number,
      };
    }).toList();

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? 'Select contacts'
              : '${_selected.length} selected',
        ),
      ),

      // ✅ WHATSAPP-STYLE SEND BUTTON (BOTTOM)
      bottomNavigationBar: _selected.isEmpty
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Send (${_selected.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                final selected = _selected.contains(contact);

                return ListTile(
                  onTap: () => _toggle(contact),
                  leading: CircleAvatar(
                    child: Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0]
                          : '?',
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.phones.first.number),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                        ),
                );
              },
            ),
    );
  }
}
