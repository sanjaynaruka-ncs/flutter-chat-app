import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../controllers/chat_audio_mode_controller.dart';
import '../controllers/chat_emoji_controller.dart';
import 'chat_audio_input_area.dart';
import 'chat_attachment_sheet.dart';
import 'chat_emoji_picker.dart';

/// 💬 ChatInputBar
///
/// RESPONSIBILITIES:
/// - Text input + send
/// - Emoji picker
/// - Attachment sheet (Gallery / Document / Contact / Location / Audio)
/// - Audio recording (mic)
/// - Audio file picking (device audio files)
///
/// ❌ DOES NOT:
/// - Upload files
/// - Write Firestore
/// - Handle chat business logic
///
/// All media handling is delegated upward via callbacks.
class ChatInputBar extends StatefulWidget {
  /// 💬 TEXT
  final ValueChanged<String> onSend;


  /// 📷 / 🎥 MEDIA
  final VoidCallback? onCameraTap;
  final VoidCallback? onVideoTap;

  /// 📄 DOCUMENT
  final VoidCallback? onDocumentTap;

  /// 🔊 AUDIO (recorded OR picked file)
  final ValueChanged<String>? onAudioSend;

  /// 👤 / 📍
  final VoidCallback? onContactTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onGalleryTap;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onCameraTap,
    this.onVideoTap,
    this.onDocumentTap,
    this.onAudioSend,
    this.onContactTap,
    this.onLocationTap,
    this.onGalleryTap,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  // ─────────────────────────────────────────────
  // 💬 SEND TEXT
  // ─────────────────────────────────────────────
  void _handleSendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  // ─────────────────────────────────────────────
  // 🔊 PICK AUDIO FILE (DEVICE AUDIO FOLDER)
  // ⚠️ CRITICAL: DO NOT POP ROUTE BEFORE PICK
  // ─────────────────────────────────────────────
  Future<void> _pickAudioFile(BuildContext sheetContext) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    debugPrint(
      '🎧 [ChatInputBar] Audio file selected → ${file.path}',
    );

    // ✅ Close attachment sheet ONCE
    Navigator.of(sheetContext).pop();

    // ✅ Send audio path upward
    widget.onAudioSend?.call(file.path!);
  }

  // ─────────────────────────────────────────────
  // 📎 ATTACHMENT SHEET (UI ONLY)
  // ─────────────────────────────────────────────
  void _openAttachmentSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return ChatAttachmentSheet(
        // 🖼️ GALLERY — FIXED
        onGalleryTap: () {
          Navigator.of(sheetContext);
          widget.onGalleryTap?.call();
        },
        // 📄 DOCUMENT
        onDocumentTap: () {
          Navigator.of(sheetContext);
          widget.onDocumentTap?.call();
        },

        // 👤 CONTACT
        onContactTap: () {
          Navigator.of(sheetContext);
          widget.onContactTap?.call();
        },

        // 📍 LOCATION
        onLocationTap: () {
          Navigator.of(sheetContext);
          widget.onLocationTap?.call();
        },

        // 🔊 AUDIO (file picker handles its own pop)
        onAudioTap: () {
          _pickAudioFile(sheetContext);
        },
      );
    },
  );
}


  // ─────────────────────────────────────────────
  // 📸 / 🎥 CAMERA + VIDEO
  // ─────────────────────────────────────────────
  void _openMediaChooser() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (mediaContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(mediaContext).pop();
                  widget.onCameraTap?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.of(mediaContext).pop();
                  widget.onVideoTap?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatAudioModeController()),
        ChangeNotifierProvider(create: (_) => ChatEmojiController()),
      ],
      child: Consumer2<ChatAudioModeController, ChatEmojiController>(
        builder: (context, audio, emojiCtrl, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: audio.isIdle
                            ? _buildTextInput(emojiCtrl)
                            : ChatAudioInputArea(
                                onSendAudio: (path) {
                                  widget.onAudioSend?.call(path);
                                },
                              ),
                      ),
                      const SizedBox(width: 6),
                      _buildRightAction(audio),
                    ],
                  ),
                ),
              ),
              if (emojiCtrl.isEmojiVisible)
                ChatEmojiPicker(
                  onEmojiSelected: _insertEmoji,
                ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 😊 EMOJI INSERT
  // ─────────────────────────────────────────────
  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;

    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, emoji);
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: start + emoji.length);
  }

  Widget _buildTextInput(ChatEmojiController emojiCtrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              emojiCtrl.isEmojiVisible
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined,
            ),
            onPressed: () {
              if (emojiCtrl.isEmojiVisible) {
                emojiCtrl.hideEmoji();
                FocusScope.of(context).requestFocus(_textFocusNode);
              } else {
                FocusScope.of(context).unfocus();
                emojiCtrl.showEmoji();
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _openAttachmentSheet,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _openMediaChooser,
          ),
        ],
      ),
    );
  }

  Widget _buildRightAction(ChatAudioModeController audio) {
    if (_hasText && audio.isIdle) {
      return _CircleButton(
        color: const Color(0xFF25D366),
        icon: Icons.send,
        onTap: _handleSendText,
      );
    }

    if (audio.isIdle) {
      return _CircleButton(
        color: const Color(0xFF25D366),
        icon: Icons.mic,
        onTap: audio.startRecording,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }
}

/// 🔘 COMMON CIRCLE BUTTON
class _CircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
