import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DbCleanupScreen extends StatelessWidget {
  const DbCleanupScreen({super.key});

  Future<void> _runCleanup(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    final snapshot =
        await db.collection('conversations').get();

    final Map<String, List<DocumentSnapshot>> buckets = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isGroup'] == true) continue;

      final participants =
          List<String>.from(data['participants'] ?? []);

      if (participants.length != 2) continue;

      participants.sort();
      final canonicalId = participants.join('_');

      buckets.putIfAbsent(canonicalId, () => []);
      buckets[canonicalId]!.add(doc);
    }

    int cleaned = 0;

    for (final entry in buckets.entries) {
      final docs = entry.value;
      if (docs.length <= 1) continue;

      final canonical = docs.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => docs.first,
      );

      for (final doc in docs) {
        if (doc.id == canonical.id) continue;

        final participants =
            List<String>.from(doc['participants']);

        final Map<String, dynamic> deletedAt = {};
        for (final uid in participants) {
          deletedAt[uid] = Timestamp.now();
        }

        await db
            .collection('conversations')
            .doc(doc.id)
            .set(
          {'deletedAt': deletedAt},
          SetOptions(merge: true),
        );

        cleaned++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cleanup completed. $cleaned duplicate chats hidden.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB Cleanup')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _runCleanup(context),
          child: const Text('RUN CLEANUP (ONCE)'),
        ),
      ),
    );
  }
}
