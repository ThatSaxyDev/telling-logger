import 'device_metadata.dart';

enum LogLevel { trace, debug, info, warning, error, fatal }

/// Log category type
///
/// Simplified to 4 core types:
/// - [general] - Debug/operational logs
/// - [analytics] - User events, funnels, screen views
/// - [crash] - Errors and unhandled exceptions
/// - [performance] - Performance metrics
enum LogType {
  general,
  analytics,
  crash,
  performance,
}

extension LogLevelExtensions on LogLevel {
  /// Severity value (0 = trace, 5 = fatal)
  int get severity {
    switch (this) {
      case LogLevel.trace:
        return 0;
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
      case LogLevel.fatal:
        return 5;
    }
  }

  /// Check if this is an error level
  bool get isError => this == LogLevel.error || this == LogLevel.fatal;

  /// Check if this is warning or more severe
  bool get isWarningOrAbove => severity >= 3;

  /// Get display name
  String get displayName {
    switch (this) {
      case LogLevel.trace:
        return 'Trace';
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
      case LogLevel.fatal:
        return 'Fatal';
    }
  }
}

extension LogTypeExtensions on LogType {
  /// Get display name
  String get displayName {
    switch (this) {
      case LogType.general:
        return 'General';
      case LogType.analytics:
        return 'Analytics';
      case LogType.crash:
        return 'Crash';
      case LogType.performance:
        return 'Performance';
    }
  }

  /// Parse LogType from string with backward compatibility for deprecated types
  static LogType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'general':
      case 'log': // Legacy
      case 'error': // Legacy (type, not level)
      case 'errorr': // Legacy typo
      case 'network': // Deprecated → general
      case 'security': // Deprecated → general
      case 'custom': // Deprecated → general
        return LogType.general;
      case 'analytics':
      case 'event': // Deprecated → analytics
        return LogType.analytics;
      case 'crash':
      case 'exception': // Deprecated → crash
        return LogType.crash;
      case 'performance':
        return LogType.performance;
      default:
        return LogType.general;
    }
  }
}

class LogEvent {
  final String id;
  final LogType type;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final DeviceMetadata? deviceMetadata;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? sessionId;

  // Counter to ensure uniqueness within same microsecond
  static int _counter = 0;

  LogEvent({
    String? id,
    this.type = LogType.general,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
    this.deviceMetadata,
    this.userId,
    this.userName,
    this.userEmail,
    this.sessionId,
  }) : id = id ?? _generateUniqueId();

  /// Generates unique ID: microseconds + counter (resets at 9999)
  static String _generateUniqueId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _counter = (_counter + 1) % 10000;
    return '${timestamp}_$_counter';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'level': level.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (metadata != null) 'metadata': metadata,
      if (deviceMetadata != null) 'device': deviceMetadata!.toJson(),
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }

  /// Deserialize from JSON (for loading persisted logs)
  factory LogEvent.fromJson(Map<String, dynamic> json) {
    return LogEvent(
      id: json['id'] as String?,
      type: LogType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => LogType.general,
      ),
      level: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now().toUtc(),
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      deviceMetadata: json['device'] != null
          ? DeviceMetadata.fromJson(Map<String, dynamic>.from(json['device'] as Map))
          : null,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }
}
