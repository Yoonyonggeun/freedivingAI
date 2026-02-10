import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  final String discipline;

  const CameraScreen({
    super.key,
    required this.discipline,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use back camera by default
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isRecording) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (!_isRecording) {
      return;
    }

    try {
      final video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
      });

      if (mounted) {
        Navigator.of(context).pop(_videoPath);
      }
    } catch (e) {
      _showError('Error stopping recording: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _controller != null)
              SizedBox.expand(
                child: CameraPreview(_controller!),
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.discipline,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w), // Balance for close button
                  ],
                ),
              ),
            ),

            // Recording indicator
            if (_isRecording)
              Positioned(
                top: 80.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'RECORDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Instructions
                    if (!_isRecording)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getInstructions(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    SizedBox(height: 24.h),

                    // Record button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: _isRecording ? 32.w : 64.w,
                            height: _isRecording ? 32.w : 64.w,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.red,
                              borderRadius: BorderRadius.circular(
                                _isRecording ? 8.r : 32.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructions() {
    switch (widget.discipline) {
      case 'DYN':
        return 'Position camera to capture full body view\nKeep phone stable during recording';
      case 'DNF':
        return 'Ensure monofin is visible in frame\nMaintain steady camera angle';
      case 'DYNB':
        return 'Capture side view for best undulation analysis\nKeep entire body in frame';
      default:
        return 'Tap the button to start recording\nTap again to stop';
    }
  }
}
