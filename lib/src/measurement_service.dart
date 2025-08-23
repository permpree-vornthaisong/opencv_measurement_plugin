// lib/src/measurement_service.dart
import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'measurement_bindings.dart';
import 'measurement_data.dart';

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

      _handle = MeasurementNative.instance.init();
      _isInitialized = _handle != null;

      if (_isInitialized) {
        _statusController.add('Native measurement system initialized');
        print('Measurement system ready');
      } else {
        _statusController.add('Failed to initialize camera system');
        print('Camera initialization failed - check if camera is available');
      }

      return _isInitialized;
    } catch (e) {
      _statusController.add('Initialization error: $e');
      print('Failed to initialize measurement service: $e');
      return false;
    }
  }

  Future<bool> start() async {
    if (_handle == null || _isRunning) {
      print('Cannot start: handle=${_handle != null}, running=$_isRunning');
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
      print('Measurement system started - polling at 30 FPS');

      return true;
    } catch (e) {
      _statusController.add('Start error: $e');
      print('Error starting measurement system: $e');
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

      // Debug output occasionally
      if (DateTime.now().millisecond < 33) {
        print('$data');
      }
    } catch (e) {
      print('Error updating measurements: $e');
      _statusController.add('Measurement update error');
    }
  }

  void _updateFrames() {
    if (_handle == null || !_isRunning) return;

    try {
      final frameData = MeasurementNative.instance.getFrame(_handle!);
      if (frameData != null) {
        print('Frame retrieved: ${frameData.length} bytes');
        _frameController.add(frameData);
      } else {
        print('No frame data available');
        _frameController.add(null);
      }
    } catch (e) {
      print('Error updating frame: $e');
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
      print('Measurement system stopped');
    } catch (e) {
      print('Error stopping measurement system: $e');
    }
  }

  Future<bool> setDetectionMode(String mode) async {
    if (_handle == null) return false;

    try {
      return MeasurementNative.instance.setMode(_handle!, mode);
    } catch (e) {
      print('Error setting detection mode: $e');
      return false;
    }
  }

  void dispose() {
    try {
      print('Disposing measurement service...');

      stop();

      if (_handle != null) {
        MeasurementNative.instance.destroy(_handle!);
        _handle = null;
      }

      _measurementController.close();
      _statusController.close();
      _frameController.close();
      _isInitialized = false;

      print('Measurement service disposed');
    } catch (e) {
      print('Error disposing measurement service: $e');
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
