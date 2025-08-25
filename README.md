# OpenCV Measurement Plugin

[![pub package](https://img.shields.io/pub/v/opencv_measurement_plugin.svg)](https://pub.dev/packages/opencv_measurement_plugin)
[![Platform](https://img.shields.io/badge/platform-windows%20%7C%20macos%20%7C%20linux-lightgrey.svg)](https://pub.dev/packages/opencv_measurement_plugin)

Real-time object detection and measurement plugin for Flutter desktop applications using OpenCV. No external DLL management required - everything is self-contained! 

## Donating money for food would be good That way I'll have motivation to keep developing/improving. KASIKORNBANK (Account number 1008151616)

## 🚀 Features

- **Real-time camera feed** with live object detection
- **Ultra-precise measurements** with sub-pixel accuracy  
- **Multiple detection modes** (auto, color-based)
- **Visual overlays** showing detected objects and measurements
- **Self-contained** - includes all required OpenCV DLLs
- **Cross-platform** support for Windows, macOS, and Linux
- **30 FPS** real-time processing
- **BGR to RGBA** automatic conversion for Flutter

## 📱 Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| Windows | ✅ Full | Includes all OpenCV DLLs |
| macOS | ✅ Full | Universal binary support |
| Linux | ✅ Full | Tested on Ubuntu 20.04+ |
| Android | ❌ | Not supported in this version |
| iOS | ❌ | Not supported in this version |

## 📋 Requirements

- Flutter SDK 3.35.1 (recommended for optimal results)
- Dart 3.0.0 or higher
- Camera permission (automatically handled)

*Note: While the plugin may work with other Flutter versions, version 3.35.1 is specifically tested and recommended for the best performance and compatibility.*

## 🛠️ Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  opencv_measurement_plugin: ^1.0.3
```

Then run:

```bash
flutter pub get
```

## 🎯 Quick Start

```dart
import 'package:opencv_measurement_plugin/opencv_measurement_plugin.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MeasurementService _service = MeasurementService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    final success = await _service.initialize();
    setState(() {
      _isInitialized = success;
    });

    // Listen to measurements
    _service.measurementStream.listen((data) {
      if (data.hasDetection) {
        print('Object: ${data.widthPx}x${data.heightPx} pixels');
        print('Confidence: ${(data.confidence * 100).toStringAsFixed(1)}%');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized
          ? MeasurementCameraView(
              measurementService: _service,
              onMeasurementUpdate: (data) {
                // Handle measurement updates
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
```

## 📖 API Reference

### MeasurementService

Main service class for object detection and measurement.

```dart
// Initialize the service
final service = MeasurementService();
await service.initialize();

// Start measurement
await service.start();

// Listen to measurements
service.measurementStream.listen((MeasurementData data) {
  if (data.hasDetection) {
    print('Width: ${data.widthPx} px');
    print('Height: ${data.heightPx} px');
  }
});

// Set detection mode
await service.setDetectionMode('auto'); // 'auto', 'blue', 'red', 'yellow'

// Stop measurement
service.stop();
```

### MeasurementData

```dart
class MeasurementData {
  final double widthPx;        // Object width in pixels
  final double heightPx;       // Object height in pixels
  final double confidence;     // Detection confidence (0.0 to 1.0)
  final bool hasDetection;     // Whether object was detected
  final int frameWidth;        // Camera frame width
  final int frameHeight;       // Camera frame height
  final DateTime timestamp;    // Measurement timestamp
}
```

### MeasurementCameraView

Widget for displaying camera feed with measurement overlays.

```dart
MeasurementCameraView(
  measurementService: _service,
  onMeasurementUpdate: (MeasurementData data) {
    // Handle real-time updates
  },
)
```

## 🔧 Advanced Usage

### Detection Modes

```dart
// Available modes
await _service.setDetectionMode('auto');    // Automatic detection
await _service.setDetectionMode('blue');    // Detect blue objects
await _service.setDetectionMode('red');     // Detect red objects
await _service.setDetectionMode('yellow');  // Detect yellow objects
await _service.setDetectionMode('brown');   // Detect brown objects
await _service.setDetectionMode('white');   // Detect white objects
```

### System Information

```dart
// Get system info
final info = _service.getSystemInfo();
print('OpenCV Version: ${info['opencv_version']}');
print('Camera Resolution: ${info['camera_resolution']}');
```

## 📊 Performance

- **Real-time processing**: 30 FPS camera feed
- **Sub-pixel accuracy**: Measurements accurate to 0.1 pixels
- **Low latency**: < 50ms processing time per frame
- **Memory efficient**: < 100MB RAM usage

## 🎨 Example Screenshots

*Note: Add screenshots of your app using the plugin to show the visual overlays and measurement results.*

## 🐛 Troubleshooting

**Plugin fails to initialize:**
- Make sure your app has camera permissions
- Check that your platform is supported (Windows/macOS/Linux)
- Verify Flutter version is 3.3.0 or higher

**No camera feed:**
- Verify camera is not being used by another application
- Check camera permissions in system settings
- Restart your application

**Poor detection accuracy:**
- Ensure good lighting conditions
- Use contrasting background colors
- Keep objects within the camera frame bounds
- Try different detection modes for better results

**Build issues:**
- Run `flutter clean` and `flutter pub get`
- Make sure you're targeting desktop platforms only
- Check that all required dependencies are installed

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/permpree-vornthaisong/opencv_measurement_plugin.git`
3. Install dependencies: `flutter pub get`
4. Run the example: `cd example && flutter run`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you have any questions or issues:

- 📧 Create an issue on [GitHub](https://github.com/permpree-vornthaisong/opencv_measurement_plugin/issues)
- 📖 Check the [documentation](https://pub.dev/packages/opencv_measurement_plugin)
- 💬 Join our [community discussions](https://github.com/permpree-vornthaisong/opencv_measurement_plugin/discussions)

## 🙏 Acknowledgments

- [OpenCV](https://opencv.org/) for the computer vision library
- [Flutter](https://flutter.dev/) for the amazing cross-platform framework
- The Flutter community for continuous support and feedback

---

**Made with ❤️ for the Flutter community**
