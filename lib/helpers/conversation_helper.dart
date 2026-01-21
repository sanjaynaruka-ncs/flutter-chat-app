import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationHelper {
  static String getOtherUserId(List participants) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    return participants.firstWhere((uid) => uid != myUid);
  }

  static Future<String> getOtherUserPhone(
    List participants,
  ) async {
    final otherUid = getOtherUserId(participants);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .get();

    return doc.data()?['phone'] ?? 'User';
  }
}
