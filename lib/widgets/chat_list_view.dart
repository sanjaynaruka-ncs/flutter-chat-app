import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_tile.dart';
import '../helpers/contact_resolver.dart';

class ChatListView extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final void Function(String conversationId) onTap;
  final void Function(String conversationId)? onLongPress;
  final String? selectedConversationId;

  const ChatListView({
    super.key,
    required this.stream,
    required this.onTap,
    this.onLongPress,
    this.selectedConversationId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final myUid = user.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        /// 🗑️ DELETE FILTER (PER-USER, SAFE)
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          if (data['deletedAt.$myUid'] is Timestamp) {
            return false;
          }

          final deletedMap = data['deletedAt'];
          if (deletedMap is Map && deletedMap[myUid] is Timestamp) {
            return false;
          }

          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No chats yet'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final conversationId = doc.id;

            // ── CLEAR CHAT PREVIEW ──────────────────
            Timestamp? clearedAt;

            if (data['clearedAt.$myUid'] is Timestamp) {
              clearedAt = data['clearedAt.$myUid'];
            } else if (data['clearedAt'] is Map &&
                data['clearedAt'][myUid] is Timestamp) {
              clearedAt = data['clearedAt'][myUid];
            }

            String lastMessage = data['lastMessage'] ?? '';
            final Timestamp? updatedAt =
                data['updatedAt'] is Timestamp
                    ? data['updatedAt']
                    : null;

            if (clearedAt != null &&
                updatedAt != null &&
                !updatedAt.toDate().isAfter(clearedAt.toDate())) {
              lastMessage = '';
            }

            final time = updatedAt != null
                ? _formatTime(updatedAt.toDate())
                : '';

            // ── ✅ UNREAD COUNT (FINAL, CORRECT) ─────
            int unreadCount = 0;

            // 1️⃣ CANONICAL (flattened)
            final flatUnread = data['unread.$myUid'];
            if (flatUnread is int) {
              unreadCount = flatUnread;
            }

            // 2️⃣ LEGACY fallback (safe)
            if (unreadCount == 0) {
              final unreadMap = data['unread'];
              if (unreadMap is Map<String, dynamic>) {
                final v = unreadMap[myUid];
                if (v is int) unreadCount = v;
              }
            }

            final bool isSelected =
                selectedConversationId == conversationId;

            final bool isStarred = data['isStarred'] == true;

            final VoidCallback handleTap =
                () => onTap(conversationId);
            final VoidCallback handleLongPress =
                () => onLongPress?.call(conversationId);

            // ── GROUP CHAT ─────────────────────────
            if (data['isGroup'] == true) {
              final groupName = data['groupName'] ?? 'Group';

              return ChatTile(
                name: groupName,
                lastMessage: lastMessage,
                time: time,
                unreadCount: unreadCount,
                isSelected: isSelected,
                showStar: isStarred,
                onTap: handleTap,
                onLongPress: handleLongPress,
              );
            }

            // ── ONE-TO-ONE CHAT ─────────────────────
            final List<String> participants =
                List<String>.from(data['participants'] ?? []);

            final String otherUid = participants.firstWhere(
              (p) => p != myUid,
              orElse: () => '',
            );

            if (otherUid.isEmpty) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData ||
                    !userSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data()
                        as Map<String, dynamic>?;

                final phone = userData?['phone'] ?? '';
                final displayName =
                    ContactResolver.resolve(phone);

                return ChatTile(
                  name: displayName,
                  lastMessage: lastMessage,
                  time: time,
                  unreadCount: unreadCount,
                  isSelected: isSelected,
                  showStar: isStarred,
                  onTap: handleTap,
                  onLongPress: handleLongPress,
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
