import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/chat_camera_service.dart';

class ChatCameraScreen extends StatefulWidget {
  const ChatCameraScreen({super.key});

  @override
  State<ChatCameraScreen> createState() =>
      _ChatCameraScreenState();
}

class _ChatCameraScreenState extends State<ChatCameraScreen> {
  final ChatCameraService _cameraService =
      ChatCameraService();

  bool _ready = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  /// 📸 TAKE PHOTO (AUTO RETURN)
  Future<void> _takePhoto() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile file =
          await _cameraService.takePhoto();

      if (!mounted) return;

      /// 🔙 RETURN PHOTO TO CALLER
      Navigator.pop(context, file);
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready ||
        _cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    final controller = _cameraService.controller!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 📷 CAMERA PREVIEW
          Positioned.fill(
            child: CameraPreview(controller),
          ),

          /// 🔝 TOP BAR
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.pop(context),
                ),
                Row(
                  children: [
                    /// ⚡ FLASH
                    IconButton(
                      icon: Icon(
                        _cameraService.flashMode ==
                                FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await _cameraService
                            .toggleFlash();
                        setState(() {});
                      },
                    ),

                    /// 🔄 SWITCH CAMERA
                    IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await _cameraService
                            .switchCamera();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// ⬇️ SHUTTER BUTTON (PHOTO)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
