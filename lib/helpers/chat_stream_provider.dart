import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/home_filter_tabs.dart';

class ChatStreamProvider {
  static Stream<QuerySnapshot> streamFor(HomeFilter filter) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final baseRef = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid);

    switch (filter) {
      case HomeFilter.all:
        return baseRef
            .orderBy('updatedAt', descending: true)
            .snapshots();

      case HomeFilter.starred:
        return baseRef
            .where('isStarred', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
            .snapshots();

      case HomeFilter.groups:
        return baseRef
            .where('isGroup', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
            .snapshots();

      default:
        return baseRef
            .orderBy('updatedAt', descending: true)
            .snapshots();
    }
  }
}
