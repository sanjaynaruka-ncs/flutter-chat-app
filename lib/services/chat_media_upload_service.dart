import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class ChatMediaUploadService {
  ChatMediaUploadService._(); // no instance

  /// 📤 Upload chat image & return download URL
  static Future<String> uploadChatImage({
    required String localPath,
    required String conversationId,
    required String senderId,
  }) async {
    final file = File(localPath);

    if (!await file.exists()) {
      throw Exception('Image file not found at path: $localPath');
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(conversationId)
        .child(senderId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }
}
