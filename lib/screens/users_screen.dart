import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'package:tokwalker/helpers/contact_resolver.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  Future<void> _openChat(BuildContext context, String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;

    // 🔑 Stable deterministic 1-1 conversation ID
    final convoId = uid.compareTo(otherUserId) < 0
        ? '${uid}_$otherUserId'
        : '${otherUserId}_$uid';

    final convoRef =
        FirebaseFirestore.instance.collection('conversations').doc(convoId);

    // ✅ Ensure conversation exists (no destructive overwrite)
    await convoRef.set({
      'participants': [uid, otherUserId],
      'isGroup': false,
      'isStarred': false,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'unread': {
        uid: 0,
        otherUserId: 0,
      },
    }, SetOptions(merge: true));

    // 🔥 CRITICAL FIX
    // If THIS user had deleted the chat earlier,
    // make it visible again in chat list
    await convoRef.set({
      'deletedAt.$uid': FieldValue.delete(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: convoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUid = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userId = users[index].id;
              final data = users[index].data() as Map<String, dynamic>;
              final phone = data['phone'] ?? '';

              final displayName = ContactResolver.resolve(phone);

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(displayName),
                onTap: () => _openChat(context, userId),
              );
            },
          );
        },
      ),
    );
  }
}
