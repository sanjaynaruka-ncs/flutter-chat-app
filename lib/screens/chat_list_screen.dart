import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import '../widgets/chat_tile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StreamSubscription<QuerySnapshot>? _deliverySub;
  void _startDeliveryListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      debugPrint('❌ [DELIVERY] myUid is NULL');
      return;
    }

    debugPrint('🟢 [DELIVERY] Listener STARTED for myUid=$myUid');

    _deliverySub = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('senderId', isNotEqualTo: myUid)
        .snapshots()
        .listen((snapshot) {
      debugPrint(
        '📦 [DELIVERY] Snapshot received | docs=${snapshot.docs.length}',
      );

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final senderId = data['senderId'];
        final status = data['status'];
        final convoPath = doc.reference.parent.parent?.id;

        debugPrint(
          '➡️ [DELIVERY] msgId=${doc.id} '
          'convo=$convoPath '
          'sender=$senderId '
          'status=$status',
        );

        if (status == 'sent') {
          debugPrint(
            '🟡 [DELIVERY] Updating → delivered | msgId=${doc.id}',
          );

          doc.reference.update({
            'status': 'delivered',
            'deliveredAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }, onError: (e) {
      debugPrint('❌ [DELIVERY] Listener ERROR: $e');
    });
  }

  @override
  void initState() {
    super.initState();
    _startDeliveryListener();
  }

  @override
  void dispose() {
    _deliverySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: myUid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔑 CORRECT DELETE / RESTORE VISIBILITY RULE
          //
          // Hide chat ONLY IF:
          // deletedAt[myUid] exists AND deletedAt >= updatedAt
          //
          final visibleChats = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final Timestamp? updatedAt = data['updatedAt'];
            final deletedAt = data['deletedAt'];

            if (deletedAt is Map && deletedAt[myUid] is Timestamp) {
              final Timestamp deletedTime =
                  deletedAt[myUid] as Timestamp;

              if (updatedAt != null &&
                  deletedTime.compareTo(updatedAt) >= 0) {
                // ❌ Deleted and no new activity after deletion
                return false;
              }
            }

            // ✅ Visible
            return true;
          }).toList();

          if (visibleChats.isEmpty) {
            return const Center(
              child: Text('No chats yet'),
            );
          }

          return ListView.builder(
            itemCount: visibleChats.length,
            itemBuilder: (context, index) {
              final doc = visibleChats[index];
              final data = doc.data() as Map<String, dynamic>;

              final conversationId = doc.id;
              final lastMessage = data['lastMessage'] ?? '';
              final title = data['title'] ?? 'Chat';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conversationId,
                        title: title,
                      ),
                    ),
                  );
                },
                child: ChatTile(
                  name: title,
                  lastMessage: lastMessage,
                  time: '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
