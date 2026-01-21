import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_audio_mode_controller.dart';

class ChatAudioInputArea extends StatelessWidget {
  /// 🔊 FINAL AUDIO FILE PATH (controller → ChatScreen)
  final ValueChanged<String> onSendAudio;

  const ChatAudioInputArea({
    super.key,
    required this.onSendAudio,
  });

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<ChatAudioModeController>();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          if (audio.isRecording)
            const Text(
              'Recording…',
              style: TextStyle(color: Colors.red),
            ),

          if (audio.isPreview)
            const Text(
              'Voice message',
              style: TextStyle(color: Colors.black54),
            ),

          const Spacer(),

          // ⏸ STOP
          if (audio.isRecording)
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.red),
              onPressed: audio.stopRecording,
            ),

          // 🗑 / 📤 PREVIEW ACTIONS
          if (audio.isPreview) ...[
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: audio.discardRecording,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF25D366)),
              onPressed: () {
                final path = audio.audioPath;
                if (path == null) return;

                debugPrint('📤 [UI] sending audio → $path');
                onSendAudio(path);
                audio.sendRecording();
              },
            ),
          ],
        ],
      ),
    );
  }
}
