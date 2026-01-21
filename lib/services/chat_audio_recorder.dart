import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );
  }

  Future<String?> stop() async {
    await _recorder.stop();
    return _currentPath;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
