import 'package:camera/camera.dart';

class ChatCameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  FlashMode _flashMode = FlashMode.off;

  CameraController? get controller => _controller;
  FlashMode get flashMode => _flashMode;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  Future<void> initialize() async {
    _cameras ??= await availableCameras();

    final backCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    await _controller!.initialize();
  }

  // ─────────────────────────────────────────────
  // PHOTO
  // ─────────────────────────────────────────────
  Future<XFile> takePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    return await _controller!.takePicture();
  }

  // ─────────────────────────────────────────────
  // VIDEO (🔥 STEP 4)
  // ─────────────────────────────────────────────
  Future<void> startVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo) {
      return;
    }

    await _controller!.startVideoRecording();
  }

  Future<XFile> stopVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_controller!.value.isRecordingVideo) {
      throw Exception('Video not recording');
    }

    return await _controller!.stopVideoRecording();
  }

  // ─────────────────────────────────────────────
  // CAMERA TOGGLES
  // ─────────────────────────────────────────────
  Future<void> switchCamera() async {
    if (_cameras == null || _controller == null) return;

    final currentLens =
        _controller!.description.lensDirection;

    final newCamera = _cameras!.firstWhere(
      (c) => c.lensDirection != currentLens,
    );

    await _controller!.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    await _controller!.initialize();
  }

  Future<void> toggleFlash() async {
    if (_controller == null) return;

    _flashMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    await _controller!.setFlashMode(_flashMode);
  }

  // ─────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────
  void dispose() {
    _controller?.dispose();
  }
}
