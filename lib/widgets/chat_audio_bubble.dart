import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/message_status.dart'; // ✅ NEW (FOR TICKS)

/// 🔊 AUDIO MESSAGE BUBBLE (WITH READ RECEIPTS)
class ChatAudioBubble extends StatefulWidget {
  final String audioPath;
  final bool isMe;
  final int durationMs;

  /// ✅ SELECTION STATE
  final bool isSelected;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  const ChatAudioBubble({
    super.key,
    required this.audioPath,
    required this.isMe,
    required this.durationMs,
    required this.isSelected,
    required this.status, // ✅ REQUIRED
  });

  @override
  State<ChatAudioBubble> createState() => _ChatAudioBubbleState();
}

class _ChatAudioBubbleState extends State<ChatAudioBubble> {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    debugPrint('🔊 [AudioBubble] init → ${widget.audioPath}');

    _player.onPlayerComplete.listen((_) {
      debugPrint('🔊 [AudioBubble] playback completed');
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlay() async {
    debugPrint(
      '🔊 [AudioBubble] toggle play | currently=$_isPlaying',
    );

    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    final file = File(widget.audioPath);
    if (!file.existsSync()) {
      debugPrint('🔴 [AudioBubble] file not found');
      return;
    }

    await _player.play(
      DeviceFileSource(widget.audioPath),
    );

    setState(() => _isPlaying = true);
  }

  @override
  void dispose() {
    debugPrint('🔻 [AudioBubble] dispose');
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        widget.isMe ? const Color(0xFFDCF8C6) : Colors.white;

    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ▶️ PLAY / PAUSE
                GestureDetector(
                  onTap: _togglePlay,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 8),

                // ⏱ DURATION
                Text(
                  '${(widget.durationMs / 1000).round()} sec',
                  style: const TextStyle(fontSize: 12),
                ),

                // ✔✔ STATUS TICKS (ONLY FOR SENDER)
                if (widget.isMe) ...[
                  const SizedBox(width: 6),
                  _StatusTick(status: widget.status),
                ],
              ],
            ),
          ),

          if (widget.isSelected)
            Positioned.fill(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
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
