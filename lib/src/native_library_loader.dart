// src/native_library_loader.dart
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class NativeLibraryLoader {
  static DynamicLibrary? _lib;
  static Directory? _extractedDir;
  static bool _dllsExtracted = false;

  /// Get the path to the extracted DLLs directory
  static String? get extractedDllPath => _extractedDir?.path;

  /// Load native library with guaranteed DLL extraction
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
      // Ensure DLLs are extracted at initialization
      await extractAllDlls();

      if (!_dllsExtracted) {
        throw Exception('Failed to extract DLLs');
      }

      // Load from the extracted location
      final mainLibPath = path.join(_extractedDir!.path, libraryName);
      if (!File(mainLibPath).existsSync()) {
        throw Exception(
            'Main library not found after extraction: $mainLibPath');
      }

      _lib = DynamicLibrary.open(mainLibPath);
    } catch (e) {
      // Try alternative loading methods as fallback
      try {
        // Method 1: Direct loading from system path
        _lib = DynamicLibrary.open(libraryName);
      } catch (e2) {
        // Method 2: Try executable directory
        try {
          final executableDir = path.dirname(Platform.resolvedExecutable);
          final execLibPath = path.join(executableDir, libraryName);
          _lib = DynamicLibrary.open(execLibPath);
        } catch (e3) {
          throw Exception(
            'Failed to load native library: $libraryName\n'
            'Extraction error: $e\n'
            'System path error: $e2\n'
            'Executable directory error: $e3\n'
            'Please ensure the plugin is properly installed and DLLs are available.',
          );
        }
      }
    }

    return _lib!;
  }

  /// Extract all DLLs to a persistent temporary directory
  static Future<bool> extractAllDlls() async {
    if (_dllsExtracted && _extractedDir != null) {
      return true;
    }

    try {
      // Create a persistent temporary directory
      _extractedDir = Directory.systemTemp.createTempSync(
        'opencv_measurement_plugin_',
      );

      print('Extracting DLLs to: ${_extractedDir!.path}');

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
      int extractedCount = 0;
      for (final dllName in requiredDlls) {
        try {
          final data = await rootBundle.load(
            'packages/opencv_measurement_plugin/windows/$dllName',
          );
          final file = File(path.join(_extractedDir!.path, dllName));
          await file.writeAsBytes(data.buffer.asUint8List());
          extractedCount++;
          print('Successfully extracted: $dllName');
        } catch (e) {
          print('Warning: Could not extract DLL: $dllName - $e');
          // For the main library, rethrow as it's critical
          if (dllName == 'measurement_library.dll') {
            throw Exception('Failed to extract main library: $e');
          }
        }
      }

      // Consider extraction successful if at least the main library was extracted
      _dllsExtracted = extractedCount > 0 &&
          File(path.join(_extractedDir!.path, 'measurement_library.dll'))
              .existsSync();

      print('DLL extraction ${_dllsExtracted ? 'successful' : 'failed'}');
      return _dllsExtracted;
    } catch (e) {
      print('Failed to extract DLLs: $e');
      return false;
    }
  }

  /// Manually extract DLLs to a specific directory (useful for Windows apps)
  static Future<bool> extractDllsTo(String targetDirectory) async {
    try {
      final targetDir = Directory(targetDirectory);
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

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

      // Extract all DLLs from plugin assets to target directory
      int successCount = 0;
      for (final dllName in requiredDlls) {
        try {
          final data = await rootBundle.load(
            'packages/opencv_measurement_plugin/windows/$dllName',
          );
          final file = File(path.join(targetDirectory, dllName));
          await file.writeAsBytes(data.buffer.asUint8List());
          successCount++;
        } catch (e) {
          print('Warning: Could not extract DLL to target dir: $dllName - $e');
        }
      }

      return successCount > 0;
    } catch (e) {
      print('Failed to extract DLLs to target directory: $e');
      return false;
    }
  }

  /// Check if library is loaded
  static bool get isLoaded => _lib != null;

  /// Check if DLLs have been extracted
  static bool get areDllsExtracted => _dllsExtracted;

  /// Unload library (cleanup)
  static void unload() {
    _lib = null;
  }
}
