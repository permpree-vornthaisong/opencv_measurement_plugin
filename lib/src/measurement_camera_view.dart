// lib/widgets/measurement_camera_view.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'measurement_data.dart';
import 'measurement_service.dart';

class MeasurementCameraView extends StatefulWidget {
  final MeasurementService measurementService;
  final Function(MeasurementData)? onMeasurementUpdate;

  const MeasurementCameraView({
    Key? key,
    required this.measurementService,
    this.onMeasurementUpdate,
  }) : super(key: key);

  @override
  _MeasurementCameraViewState createState() => _MeasurementCameraViewState();
}

class _MeasurementCameraViewState extends State<MeasurementCameraView> {
  Uint8List? _currentFrame;
  int _frameWidth = 640;
  int _frameHeight = 480;
  MeasurementData? _currentMeasurement;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    // Listen to frame updates from native library
    widget.measurementService.frameStream.listen(
      (frameData) {
        if (mounted && frameData != null) {
          print('Camera view received frame: ${frameData.length} bytes');
          setState(() {
            _currentFrame = frameData;
          });
        } else if (mounted) {
          print('Camera view received null frame');
        }
      },
      onError: (error) {
        debugPrint('Frame stream error: $error');
      },
    );

    // Listen to measurement updates
    widget.measurementService.measurementStream.listen(
      (measurement) {
        if (mounted) {
          print(
            'Camera view received measurement: ${measurement.frameWidth}x${measurement.frameHeight}, detection: ${measurement.hasDetection}',
          );
          setState(() {
            _currentMeasurement = measurement;
            _frameWidth = measurement.frameWidth;
            _frameHeight = measurement.frameHeight;
          });

          // Notify parent widget
          widget.onMeasurementUpdate?.call(measurement);
        }
      },
      onError: (error) {
        debugPrint('Measurement stream error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: _buildCameraContent(),
    );
  }

  Widget _buildCameraContent() {
    if (_currentFrame == null) {
      return _createPlaceholder('Connecting to camera...');
    }

    return Stack(
      children: [
        // Main camera view
        Center(
          child: AspectRatio(
            aspectRatio: _frameWidth / _frameHeight,
            child: _buildImageFromBGRData(
              _currentFrame!,
              _frameWidth,
              _frameHeight,
            ),
          ),
        ),

        // Overlay information
        if (_currentMeasurement != null) _buildOverlay(),
      ],
    );
  }

  Widget _createPlaceholder(String text, {Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Icon(Icons.videocam, size: 48, color: Colors.white54),
            SizedBox(height: 8),
            Text(text, style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFromBGRData(Uint8List data, int width, int height) {
    if (data.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text('No image data', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    print(
      'Building image from BGR data: ${data.length} bytes, ${width}x${height}',
    );

    // Validate expected size
    final expectedSize = width * height * 3; // BGR = 3 channels
    if (data.length != expectedSize) {
      print(
        'Warning: Data size mismatch. Expected: $expectedSize, Got: ${data.length}',
      );
      // Try to handle the mismatch gracefully
      if (data.length < expectedSize) {
        return Container(
          color: Colors.red[100],
          child: Center(
            child: Text(
              'Image data incomplete\nExpected: $expectedSize bytes\nGot: ${data.length} bytes',
              style: TextStyle(color: Colors.red[800]),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return FutureBuilder<ui.Image>(
      future: _convertBGRToImage(data, width, height),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print('Successfully converted BGR to Flutter image');
          return RawImage(
            image: snapshot.data,
            fit: BoxFit.contain,
            width: width.toDouble(),
            height: height.toDouble(),
          );
        } else if (snapshot.hasError) {
          print('Error converting BGR to image: ${snapshot.error}');
          return Container(
            color: Colors.red[100],
            child: Center(child: Text('Image error: ${snapshot.error}')),
          );
        } else {
          return Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
      },
    );
  }

  Future<ui.Image> _convertBGRToImage(
    Uint8List bgrData,
    int width,
    int height,
  ) async {
    print(
      'Converting BGR to RGBA: ${width}x${height}, data length: ${bgrData.length}',
    );

    try {
      // Convert BGR to RGBA for Flutter
      final rgbaData = Uint8List(width * height * 4);

      final totalPixels = width * height;
      for (int i = 0; i < totalPixels; i++) {
        final bgrOffset = i * 3;
        final rgbaOffset = i * 4;

        // Bounds checking
        if (bgrOffset + 2 >= bgrData.length) {
          print('Warning: BGR data truncated at pixel $i');
          break;
        }

        // BGR to RGBA conversion
        rgbaData[rgbaOffset + 0] = bgrData[bgrOffset + 2]; // R = B
        rgbaData[rgbaOffset + 1] = bgrData[bgrOffset + 1]; // G = G
        rgbaData[rgbaOffset + 2] = bgrData[bgrOffset + 0]; // B = R
        rgbaData[rgbaOffset + 3] = 255; // A = 255 (opaque)
      }

      print('BGR to RGBA conversion completed: ${rgbaData.length} bytes');

      // Create image from RGBA data
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgbaData, width, height, ui.PixelFormat.rgba8888, (
        ui.Image result,
      ) {
        print(
          'Flutter image created successfully: ${result.width}x${result.height}',
        );
        completer.complete(result);
      });

      return completer.future;
    } catch (e) {
      print('Error in BGR to RGBA conversion: $e');
      rethrow;
    }
  }

  Widget _buildOverlay() {
    final measurement = _currentMeasurement!;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Measurements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: measurement.hasDetection
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      measurement.hasDetection ? 'DETECTED' : 'NO OBJECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (measurement.hasDetection) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'W: ${measurement.widthPx.toStringAsFixed(1)}px',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'H: ${measurement.heightPx.toStringAsFixed(1)}px',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Conf: ${(measurement.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
