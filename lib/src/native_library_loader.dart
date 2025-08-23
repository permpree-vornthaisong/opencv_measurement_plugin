// src/native_library_loader.dart
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';

class NativeLibraryLoader {
  static DynamicLibrary? _lib;

  /// Load native library from plugin assets
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
      // First try to load from the plugin bundle
      _lib = await _loadFromPluginBundle(libraryName);
    } catch (e) {
      // Fallback to system library loading
      try {
        _lib = DynamicLibrary.open(libraryName);
      } catch (e2) {
        throw Exception(
          'Failed to load native library: $libraryName\n'
          'Bundle loading error: $e\n'
          'System loading error: $e2',
        );
      }
    }

    return _lib!;
  }

  /// Load library from plugin asset bundle
  static Future<DynamicLibrary> _loadFromPluginBundle(
    String libraryName,
  ) async {
    if (Platform.isWindows) {
      // On Windows, we need to extract DLLs to a temporary location
      return await _extractAndLoadWindows(libraryName);
    } else {
      // On Unix systems, try direct loading
      return DynamicLibrary.open(libraryName);
    }
  }

  /// Extract Windows DLLs and load
  static Future<DynamicLibrary> _extractAndLoadWindows(
    String libraryName,
  ) async {
    // Get temporary directory
    final tempDir = Directory.systemTemp.createTempSync(
      'opencv_measurement_plugin_',
    );

    // List of all required DLLs
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

    // Extract all DLLs
    for (final dllName in requiredDlls) {
      try {
        final data = await rootBundle.load(
          'packages/opencv_measurement_plugin/windows/$dllName',
        );
        final file = File('${tempDir.path}\\$dllName');
        await file.writeAsBytes(data.buffer.asUint8List());
      } catch (e) {
        // Some DLLs might be optional - ignore extraction failures
      }
    }

    // Load the main library
    final mainLibPath = '${tempDir.path}\\$libraryName';
    return DynamicLibrary.open(mainLibPath);
  }

  /// Check if library is loaded
  static bool get isLoaded => _lib != null;

  /// Unload library (cleanup)
  static void unload() {
    _lib = null;
  }
}
