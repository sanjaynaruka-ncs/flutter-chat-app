import 'package:flutter/material.dart';

import 'broadcast_contact_picker_screen.dart';

class CreateBroadcastScreen extends StatefulWidget {
  const CreateBroadcastScreen({super.key});

  @override
  State<CreateBroadcastScreen> createState() =>
      _CreateBroadcastScreenState();
}

class _CreateBroadcastScreenState
    extends State<CreateBroadcastScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // ➜ Step 2: pick contacts
    final recipients = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const BroadcastContactPickerScreen(),
      ),
    );

    if (recipients == null || recipients.isEmpty) return;

    // 🔒 Return combined result to caller (step 3)
    Navigator.pop(context, {
      'name': name,
      'recipients': recipients,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New broadcast',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _onNext,
            child: const Text(
              'NEXT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcast name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter broadcast name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
