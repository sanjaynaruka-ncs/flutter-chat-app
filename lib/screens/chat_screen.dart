import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../chat/chat_screen_ui.dart';
import '../chat/chat_clear_manager.dart';
import '../chat/chat_menu_controller.dart';
import '../helpers/contact_resolver.dart';
import 'new_group_screen.dart';
// ─────────────────────────────────────────────
// 📦 CHAT SERVICES (AUTHORITATIVE WRITERS)
// ─────────────────────────────────────────────
import '../services/chat_message_service.dart';
import '../services/chat_image_service.dart';
import '../services/chat_video_service.dart';
import '../services/chat_audio_service.dart';
import '../services/chat_document_service.dart';
import '../services/chat_contact_service.dart';
import '../services/chat_location_service.dart';

// ─────────────────────────────────────────────
// 📦 PICKERS / SCREENS
// ─────────────────────────────────────────────
import 'package:file_picker/file_picker.dart';
import 'chat_contact_picker_screen.dart';
import 'chat_location_picker_screen.dart';

/// 💬 CHAT SCREEN
///
/// RESPONSIBILITIES:
/// - Owns conversationId
/// - Initializes chat services
/// - Handles UI actions (send / media / menu)
/// - Handles delivery receipts (receiver-side)
/// - Handles read receipts when chat is opened
/// - NEVER writes messages directly to Firestore
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final VoidCallback? onBack;
  final VoidCallback? onCreateGroup;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.onBack,
    this.onCreateGroup,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ─────────────────────────────────────────────
  // 🔑 CORE CONTEXT
  // ─────────────────────────────────────────────
  late final String _myUid;

  // ─────────────────────────────────────────────
  // 🧠 CONTROLLERS & SERVICES
  // ─────────────────────────────────────────────
  late final ChatMenuController _menuController;
  late final ChatMessageService _messageService;
  late final ChatImageService _imageService;
  late final ChatVideoService _videoService;
  late final ChatAudioService _audioService;
  late final ChatDocumentService _documentService;
  late final ChatContactService _contactService;
  late final ChatLocationService _locationService;

  // ─────────────────────────────────────────────
  // 🧩 UI STATE
  // ─────────────────────────────────────────────
  bool _isBlocked = false;
  String _title = 'Chat';

  final ImagePicker _picker = ImagePicker();
  StreamSubscription<QuerySnapshot>? _deliverySub;

  bool _readTriggered = false;

  // ─────────────────────────────────────────────
  // 🔄 LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _myUid = FirebaseAuth.instance.currentUser!.uid;

    _menuController = ChatMenuController(
      context: context,
      conversationId: widget.conversationId,
      myUid: _myUid,
    );

    _messageService = ChatMessageService(widget.conversationId);
    _imageService = ChatImageService(widget.conversationId);
    _videoService = ChatVideoService(widget.conversationId);
    _audioService = ChatAudioService(widget.conversationId);
    _documentService = ChatDocumentService(widget.conversationId);
    _contactService = ChatContactService(widget.conversationId);
    _locationService = ChatLocationService(widget.conversationId);

    _loadChatTitle();

    // ─────────────────────────────────────────────
    // 🔑 FIX #1 — USER OPENED CHAT → UNREAD = 0
    // ─────────────────────────────────────────────
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .set(
      {'unread.$_myUid': 0},
      SetOptions(merge: true),
    );

    // ─────────────────────────────────────────────
    // 🔑 FIX #2 — USER OPENED CHAT → READ IMMEDIATELY
    // ─────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_readTriggered) {
        _readTriggered = true;
        _messageService.markMessagesAsRead(readerId: _myUid);
      }
    });

    // ─────────────────────────────────────────────
    // 📦 RECEIVER-SIDE DELIVERY (ONLY)
    // ─────────────────────────────────────────────
    _deliverySub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: _myUid)
        .snapshots()
        .listen((_) {
          _messageService.markMessagesAsDelivered(
            receiverId: _myUid,
          );
        });
  }

  @override
  void dispose() {
    _deliverySub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 🧱 BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChatScreenUi(
      title: _title,
      messagesStream: ChatClearManager.messageStream(
        conversationId: widget.conversationId,
        myUid: _myUid,
      ),
      isBlocked: _isBlocked,
      onBack: widget.onBack ?? () => Navigator.pop(context),
      onSearch: () => _menuController.search(() => setState(() {})),
      onClearChat: () async {
        await _menuController.clearChat();
        setState(() {});
      },
      onBlock: () async {
        await _menuController.block();

        // ✅ Trust Firestore, not local guess
        final snap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();

        final blocked =
            snap.data()?['blocked.$_myUid'] == true;

        if (mounted) {
          setState(() => _isBlocked = blocked);
        }
      },

      onUnblock: () async {
        await _menuController.unblock();

        final snap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();

        final blocked =
            snap.data()?['blocked.$_myUid'] == true;

        if (mounted) {
          setState(() => _isBlocked = blocked);
        }
      },

      onReport: () async {
      // 1️⃣ Report (dialog + backend)
      await _menuController.report();
    },

      onNewGroup: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NewGroupScreen(),
          ),
        );
      },

      onSend: (text) async {
        await _messageService.sendTextMessage(
          text: text,
          senderId: _myUid,
        );
      },
      /*
      onViewContact: widget.onViewContact,

      onViewContact: (text) async {
        await _messageService.sendTextMessage(
          text: text,
          senderId: _myUid,
        );
      },
      */

      onCameraTap: _handleImageCamera,
      onVideoTap: _handleVideoCamera,
      onAudioSend: _handleAudioSend,
      onDocumentTap: _handleDocumentPick,
      onContactTap: _handleContactPick,
      onLocationTap: _handleLocationPick,
      onGalleryTap: _handleImageGallery,
    );

  }

  // ─────────────────────────────────────────────
  // MEDIA / HELPERS (UNCHANGED)
  // ─────────────────────────────────────────────
  Future<void> _handleAudioSend(String audioPath) async {
    final file = File(audioPath);
    if (!file.existsSync()) return;

    await _audioService.sendAudio(
      localAudioPath: audioPath,
      durationMs: 0,
      clientId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _handleDocumentPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    await _documentService.sendDocument(
      localPath: file.path!,
      fileName: file.name,
      fileSize: file.size,
    );
  }

  Future<void> _handleImageGallery() async {
  final XFile? file = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 100,
  );
  if (file == null) return;

  await _imageService.sendImage(localImagePath: file.path);
}

  Future<void> _handleContactPick() async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatContactPickerScreen(),
      ),
    );
    if (result == null || result.isEmpty) return;

    for (final c in result) {
      await _contactService.sendContact(
        name: c['name'] ?? '',
        phone: c['phone'] ?? '',
      );
    }
  }

  Future<void> _handleLocationPick() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatLocationPickerScreen(),
      ),
    );
    if (result == null) return;

    await _locationService.sendLocation(
      lat: result['lat'],
      lng: result['lng'],
      placeName: 'Shared location',
    );
  }

  Future<void> _handleImageCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (file == null) return;

    await _imageService.sendImage(localImagePath: file.path);
  }

  Future<void> _handleVideoCamera() async {
    final XFile? file =
        await _picker.pickVideo(source: ImageSource.camera);
    if (file == null) return;

    await _videoService.sendVideo(
      localVideoPath: file.path,
      clientId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _loadChatTitle() async {
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    final data = snap.data();
    if (data == null) return;

    if (data['isGroup'] == true) {
      setState(() => _title = data['groupName'] ?? 'Group');
      return;
    }

    final participants =
        List<String>.from(data['participants'] ?? []);
    final otherUid =
        participants.firstWhere((u) => u != _myUid, orElse: () => '');

    if (otherUid.isEmpty) return;

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .get();

    final phone = userSnap.data()?['phone'] ?? '';
    final resolvedName = ContactResolver.resolve(phone);

    setState(() {
      _title = resolvedName.isNotEmpty ? resolvedName : 'Chat';
    });
  }
}
