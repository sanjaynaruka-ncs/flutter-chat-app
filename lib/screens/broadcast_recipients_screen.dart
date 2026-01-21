import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../helpers/contact_resolver.dart';

class BroadcastRecipientsScreen extends StatefulWidget {
  final String broadcastId;

  const BroadcastRecipientsScreen({
    super.key,
    required this.broadcastId,
  });

  @override
  State<BroadcastRecipientsScreen> createState() =>
      _BroadcastRecipientsScreenState();
}

class _BroadcastRecipientsScreenState
    extends State<BroadcastRecipientsScreen> {
  final Set<String> _selectedUserIds = {};
  bool _loading = true;

  String get _myUid =>
      FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadExistingRecipients();
  }

  Future<void> _loadExistingRecipients() async {
    final doc = await FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(widget.broadcastId)
        .get();

    final data = doc.data();
    final members =
        List<String>.from(data?['members'] ?? []);

    setState(() {
      _selectedUserIds.addAll(members);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Broadcast recipients',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _selectedUserIds.isEmpty
                ? null
                : _onSave,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _selectedUserIds.isEmpty
                    ? Colors.grey
                    : Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != _myUid)
                    .toList();

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final userId = doc.id;
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final phone = data['phone'] ?? '';
                    final name =
                        ContactResolver.resolve(phone);

                    final isSelected =
                        _selectedUserIds.contains(userId);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.green.shade600,
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds
                                  .remove(userId);
                            } else {
                              _selectedUserIds.add(userId);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUserIds.remove(userId);
                          } else {
                            _selectedUserIds.add(userId);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _onSave() {
    Navigator.pop(
      context,
      _selectedUserIds.toList(),
    );
  }
}
