// lib/native/measurement_bindings.dart
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// C structures matching C++ definitions
final class MeasurementResult extends Struct {
  @Double()
  external double widthPx;

  @Double()
  external double heightPx;

  @Double()
  external double confidence;

  @Int32()
  external int hasDetection;

  @Int32()
  external int frameWidth;

  @Int32()
  external int frameHeight;

  @Int64()
  external int timestamp;
}

final class FrameData extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int width;

  @Int32()
  external int height;

  @Int32()
  external int channels;

  @Int32()
  external int size;
}

// Native library interface
class MeasurementNative {
  static DynamicLibrary? _lib;

  // Function signatures
  late final Pointer<NativeType> Function() _measurementInit;
  late final bool Function(Pointer<NativeType>) _measurementStart;
  late final MeasurementResult Function(Pointer<NativeType>)
  _measurementGetResult;
  late final Pointer<FrameData> Function(Pointer<NativeType>)
  _measurementGetFrame;
  late final void Function(Pointer<FrameData>) _measurementFreeFrame;
  late final bool Function(Pointer<NativeType>, Pointer<Utf8>)
  _measurementSetMode;
  late final void Function(Pointer<NativeType>) _measurementStop;
  late final void Function(Pointer<NativeType>) _measurementDestroy;

  static MeasurementNative? _instance;

  MeasurementNative._internal() {
    _loadLibrary();
    _loadFunctions();
  }

  static MeasurementNative get instance {
    _instance ??= MeasurementNative._internal();
    return _instance!;
  }

  void _loadLibrary() {
    String libraryPath;

    if (Platform.isWindows) {
      libraryPath = 'measurement_library.dll';
    } else if (Platform.isMacOS) {
      libraryPath = 'libmeasurement_library.dylib';
    } else if (Platform.isLinux) {
      libraryPath = 'libmeasurement_library.so';
    } else {
      throw UnsupportedError('Platform not supported');
    }

    try {
      _lib = DynamicLibrary.open(libraryPath);
    } catch (e) {
      throw Exception('Failed to load native library: $e');
    }
  }

  void _loadFunctions() {
    if (_lib == null) throw Exception('Library not loaded');

    _measurementInit = _lib!
        .lookup<NativeFunction<Pointer<NativeType> Function()>>(
          'measurement_init',
        )
        .asFunction();

    _measurementStart = _lib!
        .lookup<NativeFunction<Bool Function(Pointer<NativeType>)>>(
          'measurement_start',
        )
        .asFunction();

    _measurementGetResult = _lib!
        .lookup<
          NativeFunction<MeasurementResult Function(Pointer<NativeType>)>
        >('measurement_get_result')
        .asFunction();

    _measurementGetFrame = _lib!
        .lookup<
          NativeFunction<Pointer<FrameData> Function(Pointer<NativeType>)>
        >('measurement_get_frame')
        .asFunction();

    _measurementFreeFrame = _lib!
        .lookup<NativeFunction<Void Function(Pointer<FrameData>)>>(
          'measurement_free_frame',
        )
        .asFunction();

    _measurementSetMode = _lib!
        .lookup<
          NativeFunction<Bool Function(Pointer<NativeType>, Pointer<Utf8>)>
        >('measurement_set_mode')
        .asFunction();

    _measurementStop = _lib!
        .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
          'measurement_stop',
        )
        .asFunction();

    _measurementDestroy = _lib!
        .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
          'measurement_destroy',
        )
        .asFunction();
  }

  // Public API
  Pointer<NativeType>? init() {
    try {
      final handle = _measurementInit();
      return handle.address == 0 ? null : handle;
    } catch (e) {
      print('Error initializing measurement system: $e');
      return null;
    }
  }

  bool start(Pointer<NativeType> handle) {
    return _measurementStart(handle);
  }

  MeasurementResult getResult(Pointer<NativeType> handle) {
    return _measurementGetResult(handle);
  }

  Map<String, int>? getFrameInfo(Pointer<NativeType> handle) {
    final framePtr = _measurementGetFrame(handle);

    if (framePtr.address == 0) return null;

    try {
      final frame = framePtr.ref;
      final info = {
        'width': frame.width,
        'height': frame.height,
        'channels': frame.channels,
        'size': frame.size,
      };

      // Free the frame data immediately since we only need metadata
      _measurementFreeFrame(framePtr);

      return info;
    } catch (e) {
      _measurementFreeFrame(framePtr);
      return null;
    }
  }

  Uint8List? getFrame(Pointer<NativeType> handle) {
    final framePtr = _measurementGetFrame(handle);

    if (framePtr.address == 0) {
      print('Warning: getFrame returned null pointer');
      return null;
    }

    try {
      final frame = framePtr.ref;

      // Debug frame metadata
      print(
        'Frame data - Width: ${frame.width}, Height: ${frame.height}, Channels: ${frame.channels}, Size: ${frame.size}',
      );

      if (frame.size <= 0 || frame.width <= 0 || frame.height <= 0) {
        print('Error: Invalid frame dimensions');
        _measurementFreeFrame(framePtr);
        return null;
      }

      final data = frame.data.asTypedList(frame.size);
      final result = Uint8List.fromList(data);

      // Free the frame data
      _measurementFreeFrame(framePtr);

      print('Successfully retrieved frame: ${result.length} bytes');
      return result;
    } catch (e) {
      print('Error in getFrame: $e');
      _measurementFreeFrame(framePtr);
      return null;
    }
  }

  bool setMode(Pointer<NativeType> handle, String mode) {
    final modePtr = mode.toNativeUtf8();
    try {
      return _measurementSetMode(handle, modePtr);
    } finally {
      malloc.free(modePtr);
    }
  }

  void stop(Pointer<NativeType> handle) {
    _measurementStop(handle);
  }

  void destroy(Pointer<NativeType> handle) {
    _measurementDestroy(handle);
  }

  // Check if library is loaded
  bool get isLoaded => _lib != null;

  // Get library path for debugging
  String get libraryInfo {
    if (_lib != null) {
      return 'Native library loaded successfully';
    } else {
      return 'Native library not loaded';
    }
  }
}
