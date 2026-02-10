import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Metadata extracted from source video via FFprobe.
class VideoMetadata {
  final double durationSec;
  final double originalFps;
  final int width;
  final int height;
  final int rotationDegrees;
  final int extractedFrameCount;

  VideoMetadata({
    required this.durationSec,
    required this.originalFps,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.extractedFrameCount,
  });

  Map<String, dynamic> toJson() => {
    'durationSec': durationSec,
    'originalFps': originalFps,
    'width': width,
    'height': height,
    'rotationDegrees': rotationDegrees,
    'extractedFrameCount': extractedFrameCount,
  };
}

/// Bundles extracted frame paths with video metadata.
class ExtractionResult {
  final List<String> framePaths;
  final VideoMetadata metadata;

  ExtractionResult({required this.framePaths, required this.metadata});
}

/// Extracts video frames using FFmpeg for pose analysis
///
/// Key features:
/// - Low frame rate (5 fps) to reduce ML Kit cost
/// - Downscaled resolution (720p) for faster processing
/// - Automatic temp file cleanup
/// - Cross-platform support via FFmpeg
class VideoFrameExtractor {
  /// Default extraction parameters (optimized for DNF analysis)
  static const int defaultFps = 5;
  static const String defaultScale = '720:-2'; // 720p width, auto height
  static const int defaultQuality = 4; // JPEG quality (1=best, 31=worst)

  String? _tempDirectory;

  /// Extract frames from video file and probe metadata.
  ///
  /// Returns [ExtractionResult] containing frame paths and [VideoMetadata].
  /// Rotation metadata is applied during extraction so output frames are
  /// always upright; the returned [VideoMetadata] reflects the corrected
  /// dimensions with `rotationDegrees = 0`.
  Future<ExtractionResult> extractFrames(
    String videoPath, {
    int fps = defaultFps,
    String scale = defaultScale,
    int quality = defaultQuality,
  }) async {
    // 1. Probe metadata BEFORE building FFmpeg command
    final probedMeta = await getVideoMetadata(videoPath);
    final rotation = probedMeta.rotationDegrees;

    // 2. Create temp directory for this extraction
    _tempDirectory = await _createTempDirectory();

    // 3. Build output pattern
    final outputPattern = path.join(_tempDirectory!, 'frame_%05d.jpg');

    // 4. Build rotation-aware video filter chain
    final filters = <String>[];

    // Prepend transpose filter based on rotation
    if (rotation == 90) {
      filters.add('transpose=1');
    } else if (rotation == 180) {
      filters.add('transpose=1,transpose=1');
    } else if (rotation == 270) {
      filters.add('transpose=2');
    }

    filters.add('fps=$fps');
    filters.add('scale=$scale');

    final vfArg = filters.join(',');

    // -noautorotate: disable FFmpeg's default auto-rotation so our explicit
    // transpose filter is the only rotation applied.
    // -metadata:s:v rotate=0: strip rotation metadata from output.
    final command = '-noautorotate -i "$videoPath" -vf "$vfArg" -metadata:s:v rotate=0 -q:v $quality "$outputPattern"';

    print('[VideoFrameExtractor] Executing FFmpeg: $command');

    // 5. Execute FFmpeg
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      throw Exception('FFmpeg frame extraction failed: $output');
    }

    // 6. Get list of extracted frame paths
    final framePaths = await _getExtractedFramePaths(_tempDirectory!);

    print('[VideoFrameExtractor] Extracted ${framePaths.length} frames to $_tempDirectory');

    // 7. Build corrected metadata — swap width/height for 90/270 rotations
    final correctedWidth = (rotation == 90 || rotation == 270)
        ? probedMeta.height
        : probedMeta.width;
    final correctedHeight = (rotation == 90 || rotation == 270)
        ? probedMeta.width
        : probedMeta.height;

    final metadata = VideoMetadata(
      durationSec: probedMeta.durationSec,
      originalFps: probedMeta.originalFps,
      width: correctedWidth,
      height: correctedHeight,
      rotationDegrees: 0, // rotation has been applied
      extractedFrameCount: framePaths.length,
    );

    return ExtractionResult(framePaths: framePaths, metadata: metadata);
  }

  /// Get list of extracted frame paths from directory
  Future<List<String>> _getExtractedFramePaths(String directory) async {
    final dir = Directory(directory);
    final files = await dir.list().toList();

    final framePaths = files
        .whereType<File>()
        .where((file) => file.path.endsWith('.jpg'))
        .map((file) => file.path)
        .toList();

    // Sort by filename to maintain temporal order
    framePaths.sort();

    return framePaths;
  }

  /// Create temporary directory for frame extraction
  Future<String> _createTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extractionDir = Directory(
      path.join(tempDir.path, 'video_frames_$timestamp'),
    );

    if (!await extractionDir.exists()) {
      await extractionDir.create(recursive: true);
    }

    return extractionDir.path;
  }

  /// Clean up extracted frames to avoid storage bloat
  ///
  /// Call this after pose analysis is complete
  Future<void> cleanup() async {
    if (_tempDirectory == null) return;

    try {
      final dir = Directory(_tempDirectory!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        print('[VideoFrameExtractor] Cleaned up temp directory: $_tempDirectory');
      }
      _tempDirectory = null;
    } catch (e) {
      print('[VideoFrameExtractor] Cleanup failed: $e');
    }
  }

  /// Probe video metadata (duration, fps, resolution, rotation) via FFprobe output.
  Future<VideoMetadata> getVideoMetadata(
    String videoPath, {
    int extractedFrameCount = 0,
  }) async {
    final command = '-i "$videoPath" -hide_banner';
    final session = await FFmpegKit.execute(command);
    final output = await session.getOutput() ?? '';

    // Duration: 00:01:23.45
    double durationSec = 0;
    final durationMatch = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})')
        .firstMatch(output);
    if (durationMatch != null) {
      final hours = int.parse(durationMatch.group(1)!);
      final minutes = int.parse(durationMatch.group(2)!);
      final seconds = int.parse(durationMatch.group(3)!);
      final centis = int.parse(durationMatch.group(4)!);
      durationSec = hours * 3600.0 + minutes * 60.0 + seconds + centis / 100.0;
    }

    // FPS: "30 fps", "29.97 fps", "25 tbr"
    double originalFps = 0;
    final fpsMatch = RegExp(r'(\d+(?:\.\d+)?)\s+fps').firstMatch(output);
    if (fpsMatch != null) {
      originalFps = double.tryParse(fpsMatch.group(1)!) ?? 0;
    }

    // Resolution: "1920x1080", "720x1280"
    int width = 0, height = 0;
    final resMatch = RegExp(r'(\d{2,5})x(\d{2,5})').firstMatch(output);
    if (resMatch != null) {
      width = int.tryParse(resMatch.group(1)!) ?? 0;
      height = int.tryParse(resMatch.group(2)!) ?? 0;
    }

    // Rotation: "rotate          : 90" or "rotation of -90.00 degrees"
    int rotationDegrees = 0;
    final rotateMatch = RegExp(r'rotate\s*:\s*(-?\d+)').firstMatch(output);
    if (rotateMatch != null) {
      rotationDegrees = int.tryParse(rotateMatch.group(1)!) ?? 0;
    } else {
      final rotationMatch = RegExp(r'rotation of (-?\d+(?:\.\d+)?) degrees').firstMatch(output);
      if (rotationMatch != null) {
        rotationDegrees = double.tryParse(rotationMatch.group(1)!)?.round() ?? 0;
      }
    }

    // Normalize rotation to 0/90/180/270
    rotationDegrees = ((rotationDegrees % 360) + 360) % 360;

    print('[VideoFrameExtractor] Metadata: ${durationSec.toStringAsFixed(1)}s, '
        '${originalFps}fps, ${width}x$height, rotation=$rotationDegrees°');

    return VideoMetadata(
      durationSec: durationSec,
      originalFps: originalFps,
      width: width,
      height: height,
      rotationDegrees: rotationDegrees,
      extractedFrameCount: extractedFrameCount,
    );
  }

  /// Get frame extraction info without actually extracting
  Future<Map<String, dynamic>> getExtractionInfo(
    String videoPath, {
    int fps = defaultFps,
  }) async {
    final meta = await getVideoMetadata(videoPath);
    final estimatedFrames = (meta.durationSec * fps).toInt();
    return {
      'durationSeconds': meta.durationSec.toInt(),
      'estimatedFrames': estimatedFrames,
      'fps': fps,
    };
  }
}
