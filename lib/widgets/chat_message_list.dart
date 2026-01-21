import 'package:flutter/material.dart';

import '../models/message_status.dart';

import 'chat_message_bubble.dart';
import 'chat_image_bubble.dart';
import 'chat_video_bubble.dart';
import 'chat_audio_message_bubble.dart';
import 'chat_document_bubble.dart';
import 'chat_contact_bubble.dart';
import 'chat_location_bubble.dart';
import 'chat_date_separator.dart';

class ChatMessageList extends StatefulWidget {
  final List<ChatMessageUi> messages;
  final Set<int> selectedIndexes;
  final dynamic theme;

  /// ✅ ADDED: long-press callback for message selection
  final void Function(int index)? onMessageLongPress;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.selectedIndexes,
    this.theme,
    this.onMessageLongPress,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  double _lastMaxScroll = 0;
  int _stabilizeAttempts = 0;
  static const int _maxAttempts = 10;

  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final max = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;

      final shouldShow = (max - offset) > 120;

      if (shouldShow != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = shouldShow;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      _scrollUntilStable();
    }
  }

  void _scrollUntilStable() {
    _stabilizeAttempts = 0;
    _lastMaxScroll = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScroll();
    });
  }

  void _tryScroll() {
    if (!_scrollController.hasClients) return;

    final currentMax = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(currentMax);

    if ((currentMax - _lastMaxScroll).abs() < 1 ||
        _stabilizeAttempts >= _maxAttempts) {
      return;
    }

    _lastMaxScroll = currentMax;
    _stabilizeAttempts++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScroll();
    });

    _showScrollToBottom = false;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    setState(() {
      _showScrollToBottom = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool selectionActive = widget.selectedIndexes.isNotEmpty;

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final item = widget.messages[index];
            final bool isSelected =
                widget.selectedIndexes.contains(index);

            void handleTap() {
              if (selectionActive) {
                widget.onMessageLongPress?.call(index);
              }
            }

            void handleLongPress() {
              widget.onMessageLongPress?.call(index);
            }

            Widget child;

            if (item is ChatDateUi) {
              child = ChatDateSeparator(label: item.label);
            } else if (item is ChatImageUi) {
              child = ChatImageBubble(
                imagePath: item.imagePath,
                isMe: item.isMe,
                status: item.status,
                isSelected: isSelected,
              );
            } else if (item is ChatVideoUi) {
              child = ChatVideoBubble(
                videoPath: item.videoPath,
                isMe: item.isMe,
                status: item.status,
                isSelected: isSelected,
              );
            } else if (item is ChatAudioUi) {
              child = ChatAudioMessageBubble(
                isMe: item.isMe,
                audioUrl: item.audioPath,
                duration: item.durationMs > 0
                    ? _formatDuration(item.durationMs)
                    : '0:00',
                status: item.status,
                isSelected: isSelected,
              );
            } else if (item is ChatDocumentUi) {
              child = ChatDocumentBubble(
                isMe: item.isMe,
                fileName: item.fileName,
                fileSizeBytes: item.fileSizeBytes,
                documentUrl: item.documentUrl,
                status: item.status,
                isSelected: isSelected,
              );
            } else if (item is ChatContactUi) {
              child = ChatContactBubble(
                isMe: item.isMe,
                name: item.name,
                phone: item.phone,
                status: item.status,
                isSelected: isSelected,
              );
            } else if (item is ChatLocationUi) {
              child = ChatLocationBubble(
                isMe: item.isMe,
                mapImageUrl: item.mapImageUrl,
                status: item.status,
                isSelected: isSelected,
              );
            } else {
              final msg = item as ChatBubbleUi;
              child = ChatMessageBubble(
                key: ValueKey('msg_$index-$isSelected'),
                message: msg.text,
                isMe: msg.isMe,
                isSelected: isSelected,
                time: msg.time,
                status: msg.status,
              );
            }

            return Container(
              width: double.infinity,
              color: isSelected
                  ? Colors.grey.withOpacity(0.25)
                  : Colors.transparent,
              child: GestureDetector(
                onLongPress: handleLongPress,
                onTap: selectionActive ? handleTap : null,
                behavior: HitTestBehavior.translucent,
                child: AbsorbPointer(
                  absorbing: selectionActive,
                  child: child,
                ),
              ),
            );
          },
        ),
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _scrollToBottom,
              child: const Icon(
                Icons.keyboard_double_arrow_down,
                color: Colors.black87,
              ),
            ),
          ),
      ],
    );
  }
}

/* ───────────── UI MODELS ───────────── */

sealed class ChatMessageUi {}

class ChatDateUi extends ChatMessageUi {
  final String label;
  ChatDateUi(this.label);
}

class ChatBubbleUi extends ChatMessageUi {
  final String text;
  final bool isMe;
  final String time;
  final MessageStatus status;

  /// 🧵 OPTIONAL REPLY METADATA (MODEL-LEVEL ONLY)
  final ChatMessageUi? replyTo;

  ChatBubbleUi({
    required this.text,
    required this.isMe,
    required this.time,
    required this.status,
    this.replyTo,
  });
}

class ChatImageUi extends ChatMessageUi {
  final String imagePath;
  final bool isMe;
  final MessageStatus status;

  ChatImageUi({
    required this.imagePath,
    required this.isMe,
    required this.status,
  });
}

class ChatVideoUi extends ChatMessageUi {
  final String videoPath;
  final bool isMe;
  final String? clientId;
  final MessageStatus status;

  ChatVideoUi({
    required this.videoPath,
    required this.isMe,
    this.clientId,
    required this.status,
  });
}

class ChatAudioUi extends ChatMessageUi {
  final bool isMe;
  final String audioPath;
  final int durationMs;
  final String? clientId;
  final MessageStatus status;

  ChatAudioUi({
    required this.isMe,
    required this.audioPath,
    required this.durationMs,
    this.clientId,
    required this.status,
  });
}

class ChatDocumentUi extends ChatMessageUi {
  final bool isMe;
  final String fileName;
  final int fileSizeBytes;
  final String documentUrl;
  final MessageStatus status;

  ChatDocumentUi({
    required this.isMe,
    required this.fileName,
    required this.fileSizeBytes,
    required this.documentUrl,
    required this.status,
  });
}

class ChatContactUi extends ChatMessageUi {
  final bool isMe;
  final String name;
  final String phone;
  final MessageStatus status;

  ChatContactUi({
    required this.isMe,
    required this.name,
    required this.phone,
    required this.status,
  });
}

class ChatLocationUi extends ChatMessageUi {
  final bool isMe;
  final String mapImageUrl;
  final MessageStatus status;

  ChatLocationUi({
    required this.isMe,
    required this.mapImageUrl,
    required this.status,
  });
}

/// ⏱ helper
String _formatDuration(int ms) {
  final seconds = (ms / 1000).floor();
  final m = (seconds ~/ 60).toString();
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
