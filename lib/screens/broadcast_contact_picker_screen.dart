import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../helpers/contact_resolver.dart';
import 'broadcast_name_screen.dart';

class BroadcastContactPickerScreen extends StatefulWidget {
  const BroadcastContactPickerScreen({super.key});

  @override
  State<BroadcastContactPickerScreen> createState() =>
      _BroadcastContactPickerScreenState();
}

class _BroadcastContactPickerScreenState
    extends State<BroadcastContactPickerScreen> {
  final Set<String> _selectedUserIds = {};

  String get _currentUid =>
      FirebaseAuth.instance.currentUser!.uid;

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
            onPressed: _selectedUserIds.isEmpty
                ? null
                : () {
                    // ✅ FIX: navigate to name screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BroadcastNameScreen(
                          memberIds:
                              _selectedUserIds.toList(),
                        ),
                      ),
                    );
                  },
            child: Text(
              'Next',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != _currentUid)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Text('No contacts found'),
            );
          }

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
                leading: Stack(
                  children: [
                    CircleAvatar(
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
                    if (isSelected)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color:
                                Colors.green.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
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
}
