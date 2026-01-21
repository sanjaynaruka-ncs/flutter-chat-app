import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/message_status.dart'; // ✅ REQUIRED FOR TICKS

class ChatVideoBubble extends StatefulWidget {
  final String videoPath;
  final bool isMe;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  /// ✅ SELECTION STATE
  final bool isSelected;

  /// ⚠️ DO NOT ADD thumbnail param here
  /// Thumbnail is rendered internally to preserve API
  const ChatVideoBubble({
    super.key,
    required this.videoPath,
    required this.isMe,
    required this.status,
    required this.isSelected,
  });

  @override
  State<ChatVideoBubble> createState() => _ChatVideoBubbleState();
}

class _ChatVideoBubbleState extends State<ChatVideoBubble> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(widget.videoPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: _openFullscreen,
                child: Stack(
                  children: [
                    Container(
                      width: 220,
                      height: 140,
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // ── VIDEO SURFACE (UNCHANGED) ─────────────
                          if (_initialized)
                            AspectRatio(
                              aspectRatio:
                                  _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          else
                            const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),

                          // ── PLAY ICON OVERLAY (UNCHANGED) ─────────
                          const Icon(
                            Icons.play_circle_fill,
                            size: 48,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),

                    // ── SELECTION OVERLAY ───────────────────────
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
            ),

            // ── ✔✔ STATUS TICKS (SENDER ONLY) ───────────────
            if (widget.isMe)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: _StatusTick(status: widget.status),
              ),
          ],
        ),
      ),
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


// ─────────────────────────────────────────────
// FULLSCREEN PLAYER (UNCHANGED)
// ─────────────────────────────────────────────

class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullScreenVideoPlayer({
    required this.controller,
  });

  @override
  State<_FullScreenVideoPlayer> createState() =>
      _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState
    extends State<_FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio:
              widget.controller.value.aspectRatio,
          child: VideoPlayer(widget.controller),
        ),
      ),
    );
  }
}
