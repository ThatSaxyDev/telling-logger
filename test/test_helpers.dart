import 'package:telling_logger/src/models/log_event.dart';
import 'package:telling_logger/src/models/device_metadata.dart';
import 'package:telling_logger/src/models/session.dart';

/// Test helper utilities for creating test data
class TestHelpers {
  /// Create a test LogEvent with default values
  static LogEvent createLogEvent({
    String? id,
    LogType type = LogType.general,
    LogLevel level = LogLevel.info,
    String message = 'Test message',
    DateTime? timestamp,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    DeviceMetadata? deviceMetadata,
    String? userId,
    String? userName,
    String? userEmail,
    String? sessionId,
  }) {
    return LogEvent(
      id: id,
      type: type,
      level: level,
      message: message,
      timestamp: timestamp ?? DateTime.now(),
      stackTrace: stackTrace,
      metadata: metadata,
      deviceMetadata: deviceMetadata,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      sessionId: sessionId,
    );
  }

  /// Create a test DeviceMetadata with default values
  static DeviceMetadata createDeviceMetadata({
    String platform = 'android',
    String osVersion = '14.0',
    String deviceModel = 'Pixel 7',
    String appVersion = '1.0.0',
    String appBuildNumber = '1',
    String sessionId = 'test_session_123',
  }) {
    return DeviceMetadata(
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
      appVersion: appVersion,
      appBuildNumber: appBuildNumber,
      sessionId: sessionId,
    );
  }

  /// Create a test Session with default values
  static Session createSession({
    String sessionId = 'test_session_123',
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? userEmail,
    String? userName,
  }) {
    return Session(
      sessionId: sessionId,
      startTime: startTime ?? DateTime.now(),
      endTime: endTime,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
    );
  }

  /// Create multiple identical log events for deduplication testing
  static List<LogEvent> createDuplicateLogs({
    required int count,
    String message = 'Duplicate log',
    LogLevel level = LogLevel.info,
  }) {
    return List.generate(
      count,
      (index) => createLogEvent(
        message: message,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Create logs with different timestamps
  static List<LogEvent> createLogsWithTimestamps({
    required int count,
    required Duration interval,
  }) {
    final now = DateTime.now();
    return List.generate(
      count,
      (index) => createLogEvent(
        message: 'Log $index',
        timestamp: now.add(interval * index),
      ),
    );
  }
}
