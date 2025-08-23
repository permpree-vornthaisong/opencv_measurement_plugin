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
      title: 'OpenCV Measurement App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MeasurementHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MeasurementHomePage extends StatefulWidget {
  const MeasurementHomePage({super.key});

  @override
  State<MeasurementHomePage> createState() => _MeasurementHomePageState();
}

class _MeasurementHomePageState extends State<MeasurementHomePage> {
  final MeasurementService _service = MeasurementService();
  bool _isInitialized = false;
  bool _isStarted = false;
  String _currentMode = 'auto';
  MeasurementData? _lastMeasurement;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    try {
      final success = await _service.initialize();
      setState(() {
        _isInitialized = success;
      });

      if (success) {
        // Listen to measurements
        _service.measurementStream.listen((data) {
          setState(() {
            _lastMeasurement = data;
          });
        });
      }
    } catch (e) {
      // Handle initialization error
      setState(() {
        _isInitialized = false;
      });
      _showError('Initialization failed: $e');
    }
  }

  Future<void> _toggleMeasurement() async {
    if (!_isInitialized) return;

    try {
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
      _showError('Error toggling measurement: $e');
    }
  }

  Future<void> _changeDetectionMode(String mode) async {
    if (!_isInitialized) return;

    try {
      await _service.setDetectionMode(mode);
      setState(() {
        _currentMode = mode;
      });
    } catch (e) {
      _showError('Error changing mode: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenCV Measurement (Plugin)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Icon(
            _isInitialized ? Icons.check_circle : Icons.error,
            color: _isInitialized ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Status Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: _isInitialized ? Colors.green[50] : Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isInitialized ? Icons.check_circle : Icons.error,
                      color: _isInitialized ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Plugin Status: ${_isInitialized ? 'Ready' : 'Not Initialized'}',
                      style: TextStyle(
                        color: _isInitialized
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text('Measurement: ${_isStarted ? 'Running' : 'Stopped'}'),
                Text('Detection Mode: $_currentMode'),
                if (_lastMeasurement != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Latest Measurement:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_lastMeasurement!.hasDetection) ...[
                    Text(
                      'Width: ${_lastMeasurement!.widthPx.toStringAsFixed(1)} px',
                    ),
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
          ),

          // Camera View
          Expanded(
            child: _isInitialized
                ? MeasurementCameraView(
                    measurementService: _service,
                    onMeasurementUpdate: (data) {
                      // Additional handling if needed
                    },
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Initializing OpenCV Plugin...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isStarted
                          ? '⏹️ Stop Measurement'
                          : '▶️ Start Measurement',
                      style: const TextStyle(fontSize: 16),
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
                  children: ['auto', 'blue', 'red', 'yellow', 'brown', 'white']
                      .map((mode) {
                        return ChoiceChip(
                          label: Text(mode.toUpperCase()),
                          selected: _currentMode == mode,
                          onSelected: _isInitialized
                              ? (selected) {
                                  if (selected) _changeDetectionMode(mode);
                                }
                              : null,
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),
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
