import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tokwalker/themes/chat_theme.dart';
import 'package:tokwalker/screens/chat_image_viewer_screen.dart';

import '../models/message_status.dart'; // ✅ SINGLE SOURCE OF TRUTH
import 'chat_message_list.dart'; // ✅ FOR ChatMessageUi TYPES

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isSelected;
  final String time;
  final MessageStatus status;
  final String? imagePath;
  final ChatTheme? theme;
  final VoidCallback? onLongPress;

  /// 🧵 REPLY METADATA (OPTIONAL)
  final ChatMessageUi? replyTo;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isSelected,
    this.onLongPress,
    this.time = '12:45',
    this.status = MessageStatus.sent,
    this.imagePath,
    this.theme,
    this.replyTo, // ✅ OPTIONAL
  });

  @override
  Widget build(BuildContext context) {
    final ChatTheme resolvedTheme =
        theme ?? ChatThemeRegistry.defaultTheme;

    final Color baseBubbleColor = isMe
        ? resolvedTheme.myMessageBg
        : resolvedTheme.otherMessageBg;

    final Color bubbleColor = isSelected
        ? baseBubbleColor.withOpacity(0.6)
        : baseBubbleColor;

    final Color textColor = isMe
        ? resolvedTheme.myTextColor
        : resolvedTheme.otherTextColor;

    final Color effectiveBubbleColor =
        isSelected ? Colors.grey.shade300 : bubbleColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            _BubbleTail(
              isMe: false,
              color: effectiveBubbleColor,
            ),
          GestureDetector(
            onLongPress: onLongPress,
            onTap: isSelected
                ? () {
                    onLongPress?.call();
                  }
                : null,
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: imagePath != null
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.fromLTRB(12, 8, 8, 6),
                  decoration: BoxDecoration(
                    color: effectiveBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe
                          ? const Radius.circular(14)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(14),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: imagePath != null
                      ? _buildImage(context)
                      : _buildText(textColor, effectiveBubbleColor),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.25),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: isMe
                              ? const Radius.circular(14)
                              : const Radius.circular(4),
                          bottomRight: isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe)
            _BubbleTail(
              isMe: true,
              color: effectiveBubbleColor,
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatImageViewerScreen(
              imagePath: imagePath!,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath!),
          width: 220,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildText(Color textColor, Color bubbleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTo != null) _buildReplyPreview(bubbleColor),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.6),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              _StatusTick(status: status),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReplyPreview(Color bubbleColor) {
    final bool repliedByMe =
        replyTo is ChatBubbleUi && (replyTo as ChatBubbleUi).isMe;

    final String senderLabel = repliedByMe ? 'You' : 'Contact';

    String previewText = '';

    if (replyTo is ChatBubbleUi) {
      previewText = (replyTo as ChatBubbleUi).text;
    } else if (replyTo is ChatImageUi) {
      previewText = '🖼 Photo';
    } else if (replyTo is ChatVideoUi) {
      previewText = '🎥 Video';
    } else if (replyTo is ChatAudioUi) {
      previewText = '🎵 Audio';
    } else if (replyTo is ChatDocumentUi) {
      previewText = '📄 Document';
    } else if (replyTo is ChatContactUi) {
      previewText = '👤 Contact';
    } else if (replyTo is ChatLocationUi) {
      previewText = '📍 Location';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: bubbleColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: isMe ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTick extends StatelessWidget {
  final MessageStatus status;

  const _StatusTick({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _buildIcon(status),
    );
  }

  Widget _buildIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          key: const ValueKey(MessageStatus.sent),
          size: 20,
          color: const Color(0xFF25D366),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          key: const ValueKey(MessageStatus.delivered),
          size: 20,
          color: const Color(0xFF25D366),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all_rounded,
          key: const ValueKey(MessageStatus.read),
          size: 20,
          color: const Color(0xFF25D366),
        );
    }
  }
}

class _BubbleTail extends StatelessWidget {
  final bool isMe;
  final Color color;

  const _BubbleTail({
    required this.isMe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(
        isMe: isMe,
        color: color,
      ),
      size: const Size(6, 10),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  _BubbleTailPainter({
    required this.isMe,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isMe) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
