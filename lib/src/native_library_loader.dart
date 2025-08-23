// src/native_library_loader.dart
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class NativeLibraryLoader {
  static DynamicLibrary? _lib;

  /// Load native library with automatic DLL bundling
  static Future<DynamicLibrary> load() async {
    if (_lib != null) return _lib!;

    String libraryName;
    if (Platform.isWindows) {
      libraryName = 'measurement_library.dll';
    } else if (Platform.isMacOS) {
      libraryName = 'libmeasurement_library.dylib';
    } else if (Platform.isLinux) {
      libraryName = 'libmeasurement_library.so';
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} not supported',
      );
    }

    try {
      // Method 1: Extract from Flutter assets (primary method for published plugin)
      _lib = await _extractAndLoadFromAssets(libraryName);
    } catch (e) {
      try {
        // Method 2: Direct loading (fallback)
        _lib = DynamicLibrary.open(libraryName);
      } catch (e2) {
        throw Exception(
          'Failed to load native library: $libraryName\n'
          'Asset extraction error: $e\n'
          'Direct loading error: $e2\n'
          'Please ensure the plugin is properly installed.',
        );
      }
    }

    return _lib!;
  }

  /// Extract DLLs from Flutter assets and load
  static Future<DynamicLibrary> _extractAndLoadFromAssets(
    String libraryName,
  ) async {
    // Create temporary directory
    final tempDir = Directory.systemTemp.createTempSync(
      'opencv_measurement_plugin_',
    );

    // List of all required DLLs that must be bundled
    final requiredDlls = [
      'measurement_library.dll',
      'opencv_core4.dll',
      'opencv_imgproc4.dll',
      'opencv_imgcodecs4.dll',
      'opencv_videoio4.dll',
      'jpeg62.dll',
      'libpng16.dll',
      'tiff.dll',
      'zlib1.dll',
      'liblzma.dll',
      'libsharpyuv.dll',
      'libwebp.dll',
      'libwebpdecoder.dll',
      'libwebpdemux.dll',
      'libwebpmux.dll',
    ];

    // Extract all DLLs from plugin assets
    for (final dllName in requiredDlls) {
      try {
        final data = await rootBundle.load(
          'packages/opencv_measurement_plugin/windows/$dllName',
        );
        final file = File(path.join(tempDir.path, dllName));
        await file.writeAsBytes(data.buffer.asUint8List());
      } catch (e) {
        if (dllName == libraryName) {
          // Main library is required
          throw Exception('Failed to extract required library: $dllName');
        }
        // Other DLLs are optional - log warning but continue
        print('Warning: Could not extract optional DLL: $dllName');
      }
    }

    // Load the main library
    final mainLibPath = path.join(tempDir.path, libraryName);
    if (!File(mainLibPath).existsSync()) {
      throw Exception('Main library not found after extraction: $mainLibPath');
    }

    return DynamicLibrary.open(mainLibPath);
  }

  /// Check if library is loaded
  static bool get isLoaded => _lib != null;

  /// Unload library (cleanup)
  static void unload() {
    _lib = null;
  }
}
