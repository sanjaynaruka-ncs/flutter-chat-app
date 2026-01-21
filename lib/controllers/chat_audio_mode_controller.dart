import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// WhatsApp-style audio states
enum ChatAudioMode {
  idle,       // mic icon visible
  recording,  // recording in progress
  preview,    // recording stopped → review
}

/// 🎯 SINGLE SOURCE OF TRUTH FOR AUDIO
/// - owns AudioRecorder
/// - owns audioPath
/// - owns state machine
class ChatAudioModeController extends ChangeNotifier {
  ChatAudioMode _mode = ChatAudioMode.idle;
  final AudioRecorder _recorder = AudioRecorder();

  String? _audioPath;

  // ─────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────

  ChatAudioMode get mode => _mode;

  bool get isIdle => _mode == ChatAudioMode.idle;
  bool get isRecording => _mode == ChatAudioMode.recording;
  bool get isPreview => _mode == ChatAudioMode.preview;

  /// ✅ FINAL AUDIO FILE (USED BY UI)
  String? get audioPath => _audioPath;

  // ─────────────────────────────────────────────
  // AUDIO FLOW
  // ─────────────────────────────────────────────

  /// 🎤 Mic tapped
  Future<void> startRecording() async {
    if (_mode != ChatAudioMode.idle) return;

    debugPrint('🎙️ [AudioCtrl] startRecording');

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('🔴 [AudioCtrl] mic permission denied');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _audioPath = path;
    _mode = ChatAudioMode.recording;

    debugPrint('🎙️ [AudioCtrl] recording → $path');
    notifyListeners();
  }

  /// ⏸ Stop tapped
  Future<void> stopRecording() async {
    if (_mode != ChatAudioMode.recording) return;

    debugPrint('⏸ [AudioCtrl] stopRecording');

    final path = await _recorder.stop();

    if (path == null || !File(path).existsSync()) {
      debugPrint('🔴 [AudioCtrl] audio file missing');
      _reset();
      return;
    }

    _audioPath = path;
    _mode = ChatAudioMode.preview;

    debugPrint('🎙️ [AudioCtrl] preview → $path');
    notifyListeners();
  }

  /// 🗑 Discard tapped
  Future<void> discardRecording() async {
    if (_mode != ChatAudioMode.preview) return;

    debugPrint('🗑 [AudioCtrl] discard');

    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    _reset();
  }

  /// 📤 Send tapped
  void sendRecording() {
    if (_mode != ChatAudioMode.preview) return;

    debugPrint('📤 [AudioCtrl] send → $_audioPath');

    // ChatInputBar / ChatAudioInputArea will read audioPath
    _mode = ChatAudioMode.idle;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────

  void _reset() {
    _audioPath = null;
    _mode = ChatAudioMode.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
