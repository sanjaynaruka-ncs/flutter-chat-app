import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'chat_message_service.dart';

class ChatLocationService {
  final String conversationId;
  late final ChatMessageService _messageService;

  ChatLocationService(this.conversationId) {
    _messageService = ChatMessageService(conversationId);

    // 🧪 DEBUG — CONFIRM SERVICE CONVERSATION ID
    debugPrint(
      '🧨 [ChatLocationService] INIT with conversationId = $conversationId',
    );
  }

  /// 📍 SEND LOCATION MESSAGE (WhatsApp-style)
  Future<void> sendLocation({
    required double lat,
    required double lng,
    required String placeName,
  }) async {
    debugPrint(
      '📍 [ChatLocationService] sendLocation | lat=$lat lng=$lng | place=$placeName',
    );

    // 🧪 DEBUG — CONFIRM CONVERSATION ID AT SEND TIME
    debugPrint(
      '🧨 [ChatLocationService] sendLocation conversationId = $conversationId',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔥🔥 [ChatLocationService] ABORT: user is null');
      return;
    }

    final Timestamp now = Timestamp.now();

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    final messagesRef = convoRef.collection('messages');

    // 🗺 WhatsApp-style static map image with NIGHT MODE
    final String mapImageUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=16'
        '&size=600x300'
        '&markers=color:red|$lat,$lng'
        '&style=feature:all|element:geometry|color:0x242f3e'
        '&style=feature:all|element:labels.text.stroke|color:0x242f3e'
        '&style=feature:all|element:labels.text.fill|color:0x746855'
        '&style=feature:administrative.locality|element:labels.text.fill|color:0xd59563'
        '&style=feature:poi|element:labels.text.fill|color:0xd59563'
        '&style=feature:poi.park|element:geometry|color:0x263c3f'
        '&style=feature:poi.park|element:labels.text.fill|color:0x6b9a76'
        '&style=feature:road|element:geometry|color:0x38414e'
        '&style=feature:road|element:geometry.stroke|color:0x212a37'
        '&style=feature:road|element:labels.text.fill|color:0x9ca5b3'
        '&style=feature:road.highway|element:geometry|color:0x746855'
        '&style=feature:road.highway|element:geometry.stroke|color:0x1f2835'
        '&style=feature:road.highway|element:labels.text.fill|color:0xf3d19c'
        '&style=feature:transit|element:geometry|color:0x2f3948'
        '&style=feature:transit.station|element:labels.text.fill|color:0xd59563'
        '&style=feature:water|element:geometry|color:0x17263c'
        '&style=feature:water|element:labels.text.fill|color:0x515c6d'
        '&style=feature:water|element:labels.text.stroke|color:0x17263c'
        '&key=AIzaSyAUjnmCwkr7YOprbSjJjXw5wd4Fj5QuBqM';

    // 🧪 DEBUG — SNAPSHOT URL
    debugPrint('🔥🔥 [LocationService] GENERATED MAP URL ↓');
    debugPrint(mapImageUrl);

    // 🧪 DEBUG — FIRESTORE PAYLOAD
    debugPrint(
      '🔥🔥 [LocationService] FIRESTORE PAYLOAD → '
      'type=location | lat=$lat | lng=$lng | placeName=$placeName',
    );

    // ─────────────────────────────────────────────
    // 1️⃣ WRITE LOCATION MESSAGE (STATUS = sent)
    // ─────────────────────────────────────────────
    await messagesRef.add({
      'type': 'location',
      'lat': lat,
      'lng': lng,
      'placeName': placeName,
      'mapImageUrl': mapImageUrl,
      'senderId': user.uid,
      'createdAt': now,
      'status': 'sent', // ✅ REQUIRED FOR TICKS
    });

    debugPrint('🔥🔥 [ChatLocationService] Location message written');

    // ─────────────────────────────────────────────
    // 2️⃣ UPDATE CONVERSATION META
    // ─────────────────────────────────────────────
    await _messageService.updateAfterLocationSend(
      senderId: user.uid,
      createdAt: now,
    );

    debugPrint('🔥🔥 [ChatLocationService] Conversation meta updated');
  }
}
