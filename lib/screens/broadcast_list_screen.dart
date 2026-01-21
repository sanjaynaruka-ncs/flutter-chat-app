import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'broadcast_chat_screen.dart';
import 'broadcast_contact_picker_screen.dart';

class BroadcastListScreen extends StatefulWidget {
  const BroadcastListScreen({super.key});

  @override
  State<BroadcastListScreen> createState() =>
      _BroadcastListScreenState();
}

class _BroadcastListScreenState
    extends State<BroadcastListScreen> {
  String? _selectedBroadcastId;

  bool get _hasSelection => _selectedBroadcastId != null;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _hasSelection
            ? const Text('1 selected')
            : const Text(
                'Broadcast lists',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        elevation: 0.5,
        actions: _hasSelection
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedBroadcast,
                ),
              ]
            : [],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcasts')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              final name =
                  data['name'] ?? 'Broadcast';

              final members =
                  List<String>.from(
                    data['members'] ?? [],
                  );

              final bool isSelected =
                  _selectedBroadcastId == doc.id;

              return InkWell(
                onTap: () {
                  if (_hasSelection) {
                    setState(() {
                      _selectedBroadcastId = null;
                    });
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BroadcastChatScreen(
                        broadcastId: doc.id,
                        name: name,
                        membersCount: members.length,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  setState(() {
                    _selectedBroadcastId = doc.id;
                  });
                },
                child: Container(
                  color: isSelected
                      ? Colors.green.withOpacity(0.12)
                      : Colors.transparent,
                  child: ListTile(
                    leading: Stack(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.campaign),
                        ),
                        if (isSelected)
                          Positioned(
                            bottom: -2,
                            right: -2,
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
                    subtitle: Text(
                      '${members.length} recipients',
                      style:
                          const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // ➕ Create broadcast
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BroadcastContactPickerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteSelectedBroadcast() async {
    final id = _selectedBroadcastId;
    if (id == null) return;

    await FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(id)
        .delete();

    setState(() {
      _selectedBroadcastId = null;
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No broadcast lists yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Create a broadcast list to send messages to multiple contacts at once.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
