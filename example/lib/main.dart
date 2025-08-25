import 'package:flutter/material.dart';
import 'package:opencv_measurement_plugin/opencv_measurement_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCV Measurement Plugin Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MeasurementExamplePage(),
    );
  }
}

class MeasurementExamplePage extends StatefulWidget {
  const MeasurementExamplePage({super.key});

  @override
  State<MeasurementExamplePage> createState() => _MeasurementExamplePageState();
}

class _MeasurementExamplePageState extends State<MeasurementExamplePage> {
  final MeasurementService _service = MeasurementService();
  bool _isInitialized = false;
  bool _isStarted = false;
  String _currentMode = 'auto';
  MeasurementData? _lastMeasurement;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await _service.initialize();
      setState(() {
        _isInitialized = success;
        _isLoading = false;
        if (!success) {
          _errorMessage =
              'Failed to initialize OpenCV plugin. Please ensure your camera is available and try again.';
        }
      });

      if (success) {
        // Listen to measurements
        _service.measurementStream.listen(
          (data) {
            if (mounted) {
              setState(() {
                _lastMeasurement = data;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Measurement stream error: $error';
              });
            }
          },
        );
      }
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _isLoading = false;
        _errorMessage = 'Initialization error: $e';
      });
    }
  }

  Future<void> _toggleMeasurement() async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _errorMessage = '';
      });

      if (_isStarted) {
        _service.stop();
        setState(() {
          _isStarted = false;
        });
      } else {
        await _service.start();
        setState(() {
          _isStarted = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to ${_isStarted ? 'stop' : 'start'} measurement: $e';
      });
    }
  }

  Future<void> _changeDetectionMode(String mode) async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _errorMessage = '';
      });

      await _service.setDetectionMode(mode);
      setState(() {
        _currentMode = mode;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to change detection mode: $e';
      });
    }
  }

  Widget _buildStatusPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plugin Status: ${_isInitialized ? 'Initialized' : 'Not Initialized'}',
            style: TextStyle(
              color: _isInitialized ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Measurement: ${_isStarted ? 'Running' : 'Stopped'}'),
          Text('Detection Mode: $_currentMode'),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_lastMeasurement != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Last Measurement:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_lastMeasurement!.hasDetection) ...[
              Text('Width: ${_lastMeasurement!.widthPx.toStringAsFixed(1)} px'),
              Text(
                'Height: ${_lastMeasurement!.heightPx.toStringAsFixed(1)} px',
              ),
              Text(
                'Confidence: ${(_lastMeasurement!.confidence * 100).toStringAsFixed(1)}%',
              ),
            ] else
              const Text('No object detected'),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing OpenCV...'),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'OpenCV Plugin Failed to Initialize',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your camera permissions and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlugin,
              child: const Text('Retry Initialization'),
            ),
          ],
        ),
      );
    }

    return MeasurementCameraView(
      measurementService: _service,
      onMeasurementUpdate: (data) {
        // Additional handling if needed
      },
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Start/Stop Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isInitialized ? _toggleMeasurement : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStarted ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isStarted ? 'Stop Measurement' : 'Start Measurement',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detection Mode Selector
          const Text(
            'Detection Mode:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ['auto', 'blue', 'red', 'yellow', 'brown', 'white'].map((
              mode,
            ) {
              return ChoiceChip(
                label: Text(mode.toUpperCase()),
                selected: _currentMode == mode,
                onSelected: _isInitialized
                    ? (selected) {
                        if (selected) _changeDetectionMode(mode);
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenCV Measurement Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status Panel
          _buildStatusPanel(),

          // Camera View
          Expanded(child: _buildCameraView()),

          // Control Panel
          _buildControlPanel(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
