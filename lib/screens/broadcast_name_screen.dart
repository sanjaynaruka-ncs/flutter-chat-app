import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BroadcastNameScreen extends StatefulWidget {
  final List<String> memberIds;

  const BroadcastNameScreen({
    super.key,
    required this.memberIds,
  });

  @override
  State<BroadcastNameScreen> createState() =>
      _BroadcastNameScreenState();
}

class _BroadcastNameScreenState extends State<BroadcastNameScreen> {
  final TextEditingController _controller =
      TextEditingController();

  bool _isSaving = false;

  bool get _isValid =>
      _controller.text.trim().isNotEmpty &&
      !_isSaving;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New broadcast',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _isValid ? _createBroadcast : null,
            child: Text(
              _isSaving ? 'Creating…' : 'Create',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isValid
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.grey,
              ),
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
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter broadcast name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.memberIds.length} recipients',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 FINAL: Create broadcast (OWNER ONLY)
  Future<void> _createBroadcast() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('broadcasts')
        .add({
      'ownerId': user.uid,
      'name': _controller.text.trim(),
      'members': widget.memberIds,
      'createdAt': now,
      'updatedAt': now,
    });

    if (!mounted) return;

    Navigator.pop(context); // back to broadcast list
  }
}
