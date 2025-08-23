/// OpenCV Measurement Plugin for Flutter
/// 
/// Real-time object detection and measurement using OpenCV
/// for Windows, macOS, and Linux desktop applications.
library opencv_measurement_plugin;

import 'src/native_library_loader.dart';

// Export all public APIs
export 'src/measurement_service.dart';
export 'src/measurement_camera_view.dart';
export 'src/measurement_data.dart';

/// OpenCV Object Measurement Plugin
/// 
/// Provides real-time object detection and measurement capabilities
/// using OpenCV computer vision library. Supports Windows, macOS, and Linux.
/// 
/// ## Features
/// 
/// - **Real-time camera feed** with live object detection
/// - **Ultra-precise measurements** with sub-pixel accuracy
/// - **Multiple detection modes** (auto, color-based)
/// - **Visual overlays** showing detected objects and measurements
/// - **Self-contained** - includes all required OpenCV DLLs
/// - **Cross-platform** support for Windows, macOS, and Linux
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:opencv_measurement_plugin/opencv_measurement_plugin.dart';
/// 
/// // Optional: Proactively initialize the plugin (extracts DLLs)
/// await OpencvMeasurementPlugin.initialize();
/// 
/// final service = MeasurementService();
/// await service.initialize();
/// await service.start();
/// 
/// // Listen to measurements
/// service.measurementStream.listen((data) {
///   if (data.hasDetection) {
///     print('Object: ${data.widthPx}x${data.heightPx} pixels');
///   }
/// });
/// 
/// // Display camera view
/// MeasurementCameraView(
///   measurementService: service,
///   onMeasurementUpdate: (data) {
///     // Handle updates
///   },
/// )
///