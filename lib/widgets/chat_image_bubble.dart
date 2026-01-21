import 'dart:io';
import 'package:flutter/material.dart';

import '../models/message_status.dart'; // ✅ REQUIRED FOR TICKS

/// 🖼️ IMAGE MESSAGE BUBBLE (WITH STATUS TICKS)
class ChatImageBubble extends StatelessWidget {
  final String imagePath;
  final bool isMe;
  final MessageStatus status; // ✅ REQUIRED
  final bool isSelected; // ✅ ADDED

  const ChatImageBubble({
    super.key,
    required this.imagePath,
    required this.isMe,
    required this.status,
    required this.isSelected, // ✅ REQUIRED
  });

  bool get _isNetworkImage =>
      imagePath.startsWith('http') || imagePath.startsWith('https');

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.65;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  pageBuilder: (_, __, ___) =>
                      _FullscreenImageViewer(imagePath: imagePath),
                ),
              );
            },
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isNetworkImage
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) {
                              return _errorPlaceholder();
                            },
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return _errorPlaceholder();
                            },
                          ),
                  ),
                ),

                // ✅ SELECTION OVERLAY
                if (isSelected)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.grey.withOpacity(0.35),
                      ),
                    ),
                  ),

                // ✅ STATUS TICKS (BOTTOM RIGHT — WHATSAPP STYLE)
                if (isMe)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: _StatusTick(status: status),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Icon(Icons.broken_image),
    );
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

/// ─────────────────────────────────────────────
/// FULLSCREEN IMAGE VIEWER (UNCHANGED)
/// ─────────────────────────────────────────────
class _FullscreenImageViewer extends StatefulWidget {
  final String imagePath;

  const _FullscreenImageViewer({
    required this.imagePath,
  });

  @override
  State<_FullscreenImageViewer> createState() =>
      _FullscreenImageViewerState();
}

class _FullscreenImageViewerState
    extends State<_FullscreenImageViewer> {
  double _dragOffset = 0.0;

  bool get _isNetworkImage =>
      widget.imagePath.startsWith('http') ||
      widget.imagePath.startsWith('https');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (_) {
        if (_dragOffset.abs() > 120) {
          Navigator.pop(context);
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: Scaffold(
        backgroundColor:
            Colors.black.withOpacity(_opacityForDrag()),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: widget.imagePath,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: _isNetworkImage
                        ? Image.network(
                            widget.imagePath,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _opacityForDrag() {
    final opacity =
        1.0 - (_dragOffset.abs() / 300).clamp(0.0, 0.6);
    return opacity;
  }
}
