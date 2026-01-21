import 'package:flutter/material.dart';
import '../controllers/chat_document_controller.dart';
import '../models/message_status.dart'; // ✅ NEW (for ticks)

/// 📄 DOCUMENT MESSAGE BUBBLE
/// - Opens / downloads document
/// - Shows file name & size
/// - Shows WhatsApp-style ticks for sender
class ChatDocumentBubble extends StatefulWidget {
  final bool isMe;
  final String fileName;
  final int fileSizeBytes;
  final String documentUrl;

  /// ✅ SELECTION STATE
  final bool isSelected;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  const ChatDocumentBubble({
    super.key,
    required this.isMe,
    required this.fileName,
    required this.fileSizeBytes,
    required this.documentUrl,
    required this.isSelected,
    required this.status, // ✅ NEW
  });

  @override
  State<ChatDocumentBubble> createState() =>
      _ChatDocumentBubbleState();
}

class _ChatDocumentBubbleState extends State<ChatDocumentBubble> {
  late final ChatDocumentController _docCtrl;

  @override
  void initState() {
    super.initState();
    _docCtrl = ChatDocumentController();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isMe ? const Color(0xFFDCF8C6) : Colors.white;

    final align =
        widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: align,
        children: [
          GestureDetector(
            onTap: () {
              debugPrint('📄 [DocumentBubble] tapped');
              _docCtrl.openOrDownload(
                url: widget.documentUrl,
                fileName: widget.fileName,
              );
            },
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── DOCUMENT CONTENT ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            size: 36,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatSize(widget.fileSizeBytes),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── STATUS TICK (SENDER ONLY) ─────
                      if (widget.isMe)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _StatusTick(status: widget.status),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                if (widget.isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// ───────────────── STATUS ICON (✔ / ✔✔ / BLUE ✔✔) ─────────────────
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
