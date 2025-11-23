import 'device_metadata.dart';

enum LogLevel { trace, debug, info, warning, error, fatal }

enum LogType {
  general,
  analytics,
  event,
  performance,
  network,
  security,
  exception,
  crash,
  custom,
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
      case LogType.event:
        return 'Event';
      case LogType.performance:
        return 'Performance';
      case LogType.network:
        return 'Network';
      case LogType.security:
        return 'Security';
      case LogType.exception:
        return 'Exception';
      case LogType.crash:
        return 'Crash';
      case LogType.custom:
        return 'Custom';
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
  }) : id =
           id ??
           DateTime.now().millisecondsSinceEpoch
               .toString(); // Simple ID for now

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
}
