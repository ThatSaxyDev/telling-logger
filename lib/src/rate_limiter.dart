import 'models/log_event.dart';

/// Rate limiter to prevent log flooding and duplicate logs
class LogRateLimiter {
  /// Cache of sent log hashes with their timestamps
  final Map<String, DateTime> _sentLogs = {};

  /// Cache for per-type throttling
  final Map<String, DateTime> _lastSentByType = {};

  /// Configuration: How long to deduplicate identical logs
  Duration deduplicationWindow = const Duration(seconds: 5);

  /// Configuration: General throttle window (all types except crash/exception)
  Duration throttleWindow = const Duration(seconds: 1);

  /// Configuration: Crash/exception specific throttle (longer window)
  Duration crashThrottleWindow = const Duration(seconds: 5);

  /// Configuration: Maximum logs per second (general)
  int maxLogsPerSecond = 10;

  /// Counter for current second
  int _logsThisSecond = 0;
  DateTime? _currentSecond;

  /// Generate a hash for a log event based on message, level, and stack trace
  String _hashLog(LogEvent event) {
    final parts = [
      event.message,
      event.level.toString(),
      event.stackTrace ?? '',
    ];
    return parts.join('|').hashCode.toString();
  }

  /// Get the throttle key for a log type
  String _getThrottleKey(LogEvent event) {
    return '${event.type}_${event.level}';
  }

  /// Check if a log should be sent (not rate limited)
  bool shouldSendLog(LogEvent event) {
    final now = DateTime.now();
    final hash = _hashLog(event);
    final throttleKey = _getThrottleKey(event);

    // 1. Check deduplication (identical logs within window)
    final lastSent = _sentLogs[hash];
    if (lastSent != null && now.difference(lastSent) < deduplicationWindow) {
      return false; // Duplicate within window
    }

    // 2. Check per-second rate limit
    if (_currentSecond == null ||
        now.difference(_currentSecond!).inSeconds >= 1) {
      // New second, reset counter
      _currentSecond = now;
      _logsThisSecond = 0;
    }
    if (_logsThisSecond >= maxLogsPerSecond) {
      return false; // Rate limit exceeded
    }

    // 3. Check type-specific throttling
    final isCrashOrException = event.type == LogType.crash ||
        event.type == LogType.exception;
    final throttleDuration =
        isCrashOrException ? crashThrottleWindow : throttleWindow;

    final lastSentOfType = _lastSentByType[throttleKey];
    if (lastSentOfType != null &&
        now.difference(lastSentOfType) < throttleDuration) {
      return false; // Throttled
    }

    return true; // OK to send
  }

  /// Mark a log as sent (update caches)
  void markLogSent(LogEvent event) {
    final now = DateTime.now();
    final hash = _hashLog(event);
    final throttleKey = _getThrottleKey(event);

    _sentLogs[hash] = now;
    _lastSentByType[throttleKey] = now;
    _logsThisSecond++;
  }

  /// Clean up old entries from caches
  void cleanup() {
    final now = DateTime.now();

    // Remove old deduplication entries (older than window + buffer)
    final dedupeThreshold = now.subtract(deduplicationWindow * 2);
    _sentLogs.removeWhere((hash, time) => time.isBefore(dedupeThreshold));

    // Remove old throttle entries (older than longest throttle window + buffer)
    final throttleThreshold = now.subtract(crashThrottleWindow * 2);
    _lastSentByType.removeWhere((key, time) => time.isBefore(throttleThreshold));
  }

  /// Get statistics for monitoring
  Map<String, dynamic> getStats() {
    return {
      'cached_hashes': _sentLogs.length,
      'throttle_entries': _lastSentByType.length,
      'logs_this_second': _logsThisSecond,
    };
  }
}
