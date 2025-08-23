// src/measurement_data.dart

/// Measurement data from object detection
class MeasurementData {
  /// Object width in pixels
  final double widthPx;

  /// Object height in pixels
  final double heightPx;

  /// Detection confidence (0.0 to 1.0)
  final double confidence;

  /// Whether an object was detected
  final bool hasDetection;

  /// Frame width in pixels
  final int frameWidth;

  /// Frame height in pixels
  final int frameHeight;

  /// Timestamp when measurement was taken
  final DateTime timestamp;

  const MeasurementData({
    required this.widthPx,
    required this.heightPx,
    required this.confidence,
    required this.hasDetection,
    required this.frameWidth,
    required this.frameHeight,
    required this.timestamp,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'widthPx': widthPx,
    'heightPx': heightPx,
    'confidence': confidence,
    'hasDetection': hasDetection,
    'frameWidth': frameWidth,
    'frameHeight': frameHeight,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  /// Create from JSON map
  factory MeasurementData.fromJson(Map<String, dynamic> json) =>
      MeasurementData(
        widthPx: json['widthPx']?.toDouble() ?? 0.0,
        heightPx: json['heightPx']?.toDouble() ?? 0.0,
        confidence: json['confidence']?.toDouble() ?? 0.0,
        hasDetection: json['hasDetection'] ?? false,
        frameWidth: json['frameWidth']?.toInt() ?? 0,
        frameHeight: json['frameHeight']?.toInt() ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp']?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );

  @override
  String toString() {
    return 'MeasurementData('
        'size: ${widthPx.toStringAsFixed(1)}x${heightPx.toStringAsFixed(1)}px, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'detected: $hasDetection'
        ')';
  }

  /// Copy with new values
  MeasurementData copyWith({
    double? widthPx,
    double? heightPx,
    double? confidence,
    bool? hasDetection,
    int? frameWidth,
    int? frameHeight,
    DateTime? timestamp,
  }) => MeasurementData(
    widthPx: widthPx ?? this.widthPx,
    heightPx: heightPx ?? this.heightPx,
    confidence: confidence ?? this.confidence,
    hasDetection: hasDetection ?? this.hasDetection,
    frameWidth: frameWidth ?? this.frameWidth,
    frameHeight: frameHeight ?? this.frameHeight,
    timestamp: timestamp ?? this.timestamp,
  );
}
