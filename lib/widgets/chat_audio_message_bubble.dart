import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tokwalker/themes/chat_theme.dart';

import '../models/message_status.dart'; // ✅ NEW (for ticks)

/// 🔊 AUDIO MESSAGE BUBBLE
/// - Keeps existing audio playback UX
/// - Adds WhatsApp-style delivery/read ticks for sender
/// - Supports selection overlay
class ChatAudioMessageBubble extends StatefulWidget {
  final bool isMe;
  final String audioUrl;
  final String duration; // fallback
  final String time;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  /// ✅ SELECTION STATE
  final bool isSelected;

  final ChatTheme? theme;

  const ChatAudioMessageBubble({
    super.key,
    required this.isMe,
    required this.audioUrl,
    required this.duration,
    required this.status, // ✅ REQUIRED
    required this.isSelected, // ✅ REQUIRED
    this.time = '12:45',
    this.theme,
  });

  @override
  State<ChatAudioMessageBubble> createState() =>
      _ChatAudioMessageBubbleState();
}

class _ChatAudioMessageBubbleState
    extends State<ChatAudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();

  Duration _total = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _prepared = false;

  @override
  void initState() {
    super.initState();
    _prepareSilently();

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _total = d);
    });

    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  /// 🔑 Prepare audio silently to fetch duration
  Future<void> _prepareSilently() async {
    try {
      await _player.setVolume(0);
      await _player.play(UrlSource(widget.audioUrl));
      await _player.pause();
      await _player.seek(Duration.zero);
      await _player.setVolume(1);
      _prepared = true;
    } catch (_) {
      // fallback duration will be used
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.seek(Duration.zero);
      await _player.resume();
      setState(() => _isPlaying = true);
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ChatTheme resolvedTheme =
        widget.theme ?? ChatThemeRegistry.defaultTheme;

    final Color bubbleColor = widget.isMe
        ? resolvedTheme.myMessageBg
        : resolvedTheme.otherMessageBg;

    final Color primary = Colors.black87;
    final Color secondary = Colors.black54;

    final double progress =
        _total.inMilliseconds == 0
            ? 0
            : _position.inMilliseconds /
                _total.inMilliseconds;

    final Duration displayDuration =
        _isPlaying ? _position : _total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe)
            _BubbleTail(isMe: false, color: bubbleColor),

          Stack(
            children: [
              Container(
                width: 230,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: widget.isMe
                        ? const Radius.circular(14)
                        : const Radius.circular(4),
                    bottomRight: widget.isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _togglePlayback,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 4,
                                color: secondary.withOpacity(0.3),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0, 1),
                                child: Container(
                                  height: 4,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _prepared
                              ? _format(displayDuration)
                              : widget.duration,
                          style: TextStyle(color: primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // ⏱ TIME + ✔✔ STATUS (SENDER ONLY)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: primary.withOpacity(0.6),
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          _StatusTick(status: widget.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ SELECTION OVERLAY
              if (widget.isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.25),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: widget.isMe
                            ? const Radius.circular(14)
                            : const Radius.circular(4),
                        bottomRight: widget.isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (widget.isMe)
            _BubbleTail(isMe: true, color: bubbleColor),
        ],
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

/// Bubble tail (unchanged)
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
      painter: _BubbleTailPainter(isMe: isMe, color: color),
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
