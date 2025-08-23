// lib/src/measurement_service.dart
import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'measurement_bindings.dart';
import 'measurement_data.dart';
import 'native_library_loader.dart';

class MeasurementService {
  Pointer<NativeType>? _handle;
  Timer? _updateTimer;
  bool _isRunning = false;
  bool _isInitialized = false;

  // Streams for reactive updates
  final StreamController<MeasurementData> _measurementController =
      StreamController<MeasurementData>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<Uint8List?> _frameController =
      StreamController<Uint8List?>.broadcast();

  Stream<MeasurementData> get measurementStream =>
      _measurementController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<Uint8List?> get frameStream => _frameController.stream;

  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;

  Future<bool> initialize() async {
    try {
      _statusController.add('Initializing native measurement system...');

      // First ensure DLLs are extracted (this is now the critical step)
      final dllsExtracted = await NativeLibraryLoader.extractAllDlls();
      if (!dllsExtracted) {
        _statusController.add('Failed to extract required DLLs');
        return false;
      }

      // Now that DLLs are extracted, try to initialize the measurement system
      _handle = MeasurementNative.instance.init();
      _isInitialized = _handle != null;

      if (_isInitialized) {
        _statusController.add('Native measurement system initialized');
      } else {
        _statusController.add('Failed to initialize camera system');
      }

      return _isInitialized;
    } catch (e) {
      _statusController.add('Initialization error: $e');
      return false;
    }
  }

  Future<bool> start() async {
    if (_handle == null || _isRunning) {
      return false;
    }

    try {
      _statusController.add('Starting measurement system...');

      if (!MeasurementNative.instance.start(_handle!)) {
        _statusController.add('Failed to start measurement system');
        return false;
      }

      _isRunning = true;

      // Start periodic updates at 30 FPS for smooth video
      _updateTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
        _updateMeasurements();
        _updateFrames();
      });

      _statusController.add('Measurement system started');

      return true;
    } catch (e) {
      _statusController.add('Start error: $e');
      return false;
    }
  }

  void _updateMeasurements() {
    if (_handle == null || !_isRunning) return;

    try {
      final result = MeasurementNative.instance.getResult(_handle!);

      final data = MeasurementData(
        widthPx: result.widthPx,
        heightPx: result.heightPx,
        confidence: result.confidence,
        hasDetection: result.hasDetection != 0, // Convert int to bool
        frameWidth: result.frameWidth,
        frameHeight: result.frameHeight,
        timestamp: DateTime.fromMillisecondsSinceEpoch(result.timestamp),
      );

      _measurementController.add(data);
    } catch (e) {
      _statusController.add('Measurement update error');
    }
  }

  void _updateFrames() {
    if (_handle == null || !_isRunning) return;

    try {
      final frameData = MeasurementNative.instance.getFrame(_handle!);
      if (frameData != null) {
        _frameController.add(frameData);
      } else {
        _frameController.add(null);
      }
    } catch (e) {
      _frameController.add(null);
    }
  }

  void stop() {
    if (!_isRunning) return;

    try {
      _statusController.add('Stopping measurement system...');

      _isRunning = false;
      _updateTimer?.cancel();
      _updateTimer = null;

      if (_handle != null) {
        MeasurementNative.instance.stop(_handle!);
      }

      _statusController.add('Measurement system stopped');
    } catch (e) {
      _statusController.add('Error stopping measurement system: $e');
    }
  }

  Future<bool> setDetectionMode(String mode) async {
    if (_handle == null) return false;

    try {
      return MeasurementNative.instance.setMode(_handle!, mode);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    try {
      stop();

      if (_handle != null) {
        MeasurementNative.instance.destroy(_handle!);
        _handle = null;
      }

      _measurementController.close();
      _statusController.close();
      _frameController.close();
      _isInitialized = false;
    } catch (e) {
      // Silent cleanup failure
    }
  }

  // Get system information for debugging
  Map<String, dynamic> getSystemInfo() {
    return {
      'native_library_loaded': MeasurementNative.instance.isLoaded,
      'library_info': MeasurementNative.instance.libraryInfo,
      'is_initialized': _isInitialized,
      'is_running': _isRunning,
      'handle_valid': _handle != null,
    };
  }
}
