import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_event.dart';
import 'models/device_metadata.dart';
import 'models/session.dart';
import 'device_info_collector.dart';
import 'rate_limiter.dart';
import 'screen_tracker.dart';
import 'go_router_screen_tracker.dart';
// import 'performance_tracker.dart';

class Telling {
  static final Telling _instance = Telling._internal();
  static Telling get instance => _instance;

  String? _apiKey;
  final String _baseUrl =
      'https://tellingserver.globeapp.dev/api/v1/logs';
  bool _initialized = false;
  DeviceMetadata? _deviceMetadata;
  static const String _storageKey = 'telling_logs_buffer';
  bool _enableDebugLogs = false;

  // User context
  String? _userId;
  String? _userName;
  String? _userEmail;

  // User properties for segmentation
  final Map<String, dynamic> _userProperties = {};

  // Simple buffer to avoid spamming network
  final List<LogEvent> _buffer = [];
  Timer? _flushTimer;
  Timer? _cleanupTimer;

  // Rate limiter
  final LogRateLimiter _rateLimiter = LogRateLimiter();

  // Session tracking
  Session? _currentSession;

  // Screen tracking
  ScreenTracker? _screenTracker;
  GoRouterScreenTracker? _goRouterScreenTracker;
  DateTime? _screenStartTime;
  String? _currentScreen;

  // Performance tracking
  // PerformanceTracker? _performanceTracker;

  Telling._internal();

  // Retry tracking for failed flushes
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;
  bool _permanentFailure = false;
  DateTime? _nextRetryTime;

  // Buffer limits
  static const int _maxBufferSize = 500;
  static const int _bufferTrimSize = 400; // Trim to this when max reached

  /// Initialize the Telling SDK
  Future<void> init(
    String apiKey, {
    String? userId,
    String? userName,
    String? userEmail,
    bool? enableDebugLogs,
    // bool enablePerformanceTracking = false,
  }) async {
    _apiKey = apiKey;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _enableDebugLogs = enableDebugLogs ?? kDebugMode;

    _initialized = true;

    // Performance tracking - Disabled for MVP, uncomment when scaling
    // if (enablePerformanceTracking) {
    //   _performanceTracker = PerformanceTracker((metric, data) {
    //     log(
    //       metric,
    //       type: LogType.performance,
    //       metadata: data,
    //     );
    //   });
    //   _performanceTracker!.start();
    // }

    // Collect device metadata
    _deviceMetadata = await DeviceInfoCollector.collect();

    // Start new session
    _startNewSession();

    // Load persisted logs
    await _loadPersistedLogs();

    _startFlushTimer();

    // Setup app lifecycle listeners
    _setupAppLifecycleListeners();

    if (_enableDebugLogs) {
      print('Telling SDK Initialized');
    }
  }

  /// Enable automatic crash reporting
  void enableCrashReporting() {
    if (!_initialized) {
      if (_enableDebugLogs) {
        print(
          'Telling SDK not initialized. Call Telling.instance.init() first.',
        );
      }
      return;
    }

    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      if (_enableDebugLogs) {
        print('Telling: CAUGHT FLUTTER ERROR: ${details.exception}');
      }

      // Determine severity based on error type
      final errorString = details.exception.toString().toLowerCase();
      final isRenderIssue =
          errorString.contains('overflow') ||
          errorString.contains('renderflex') ||
          errorString.contains('renderbox') ||
          errorString.contains('disposed') ||
          errorString.contains('trying to render');

      final isLayoutIssue =
          errorString.contains('constraints') ||
          errorString.contains('size') ||
          errorString.contains('layout');

      // Framework/render issues are warnings, actual crashes are fatal
      final level = (isRenderIssue || isLayoutIssue)
          ? LogLevel.warning
          : LogLevel.fatal;
      final type = (isRenderIssue || isLayoutIssue)
          ? LogType.general
          : LogType.crash;

      log(
        'Flutter Error: ${details.exception}',
        level: level,
        error: details.exception,
        stackTrace: details.stack,
        type: type,
      );

      // Still print to console in debug mode
      if (_enableDebugLogs) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_enableDebugLogs) {
        print('Telling: CAUGHT PLATFORM ERROR: $error');
      }

      // Platform errors are usually fatal
      log(
        'Platform Error: $error',
        level: LogLevel.fatal,
        error: error,
        stackTrace: stack,
        type: LogType.crash,
      );
      return true;
    };

    if (_enableDebugLogs) {
      print('Telling: Crash reporting enabled');
    }
  }

  /// Capture and report an exception
  ///
  /// Use this to report exceptions that you've caught in try-catch blocks.
  /// This ensures handled exceptions are still tracked for debugging.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stackTrace) {
  ///   Telling.instance.captureException(
  ///     error: e,
  ///     stackTrace: stackTrace,
  ///     context: 'checkout_flow',
  ///   );
  ///   // Handle the error gracefully...
  /// }
  /// ```
  void captureException({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final enrichedMetadata = <String, dynamic>{
      'exception_type': error.runtimeType.toString(),
      if (context != null) 'context': context,
      ...?metadata,
    };

    log(
      error.toString(),
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
      metadata: enrichedMetadata,
      type: LogType.crash,
    );
  }

  /// Track an analytics event
  void event(String name, {Map<String, dynamic>? properties}) {
    log(
      name,
      level: LogLevel.info,
      metadata: properties,
      type: LogType.analytics,
    );
  }

  /// Track a funnel step
  ///
  /// **IMPORTANT:** For accurate funnel analysis, call `setUser()` BEFORE tracking
  /// any funnel steps. If you call `setUser()` mid-funnel, the backend will see
  /// steps before and after as belonging to different users, breaking the funnel.
  ///
  /// Usage:
  /// ```dart
  /// // 1. Set user first (even for anonymous users, use a temp ID)
  /// Telling.instance.setUser(userId: 'user123');
  ///
  /// // 2. Then track funnel steps
  /// Telling.instance.trackFunnel(
  ///   funnelName: 'onboarding',
  ///   stepName: 'email_entered',
  ///   step: 1,
  /// );
  /// ```
  void trackFunnel({
    required String funnelName,
    required String stepName,
    int? step,
    Map<String, dynamic>? properties,
  }) {
    log(
      'Funnel: $funnelName - $stepName',
      level: LogLevel.info,
      type: LogType.analytics,
      metadata: {
        'funnel_name': funnelName,
        'funnel_step_name': stepName,
        if (step != null) 'funnel_step_number': step,
        ...?properties,
      },
    );
  }

  /// Set user context (call after user logs in)
  void setUser({required String userId, String? userName, String? userEmail}) {
    if (!_initialized) {
      if (_enableDebugLogs) {
        print(
          'Telling SDK not initialized. Call Telling.instance.init() first.',
        );
      }
      return;
    }

    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;

    // Start a new session with the updated user context
    _endSession();
    _startNewSession();

    if (_enableDebugLogs) {
      print('Telling: User context updated - $userId');
    }

    // Log the user identification event
    log(
      'User identified',
      level: LogLevel.info,
      type: LogType.analytics,
      metadata: {
        'userId': userId,
        if (userName != null) 'userName': userName,
        if (userEmail != null) 'userEmail': userEmail,
      },
    );
  }

  /// Clear user context (call after user logs out)
  void clearUser() {
    if (!_initialized) {
      if (_enableDebugLogs) {
        print(
          'Telling SDK not initialized. Call Telling.instance.init() first.',
        );
      }
      return;
    }

    if (_enableDebugLogs) {
      print('Telling: User context cleared');
    }

    // Log the logout event before clearing
    log('User logged out', level: LogLevel.info, type: LogType.analytics);

    _userId = null;
    _userName = null;
    _userEmail = null;

    // Start a new anonymous session
    _endSession();
    _startNewSession();
  }

  /// Set a single user property
  void setUserProperty({required String key, required dynamic value}) {
    _userProperties[key] = value;

    // Log property change
    log(
      'User property set',
      type: LogType.analytics,
      metadata: {'property_key': key, 'property_value': value},
    );
  }

  /// Set multiple user properties at once
  void setUserProperties(Map<String, dynamic> properties) {
    _userProperties.addAll(properties);

    // Log property change
    log(
      'User properties set',
      type: LogType.analytics,
      metadata: {'properties': properties},
    );
  }

  /// Get a user property value
  dynamic getUserProperty(String key) {
    return _userProperties[key];
  }

  /// Clear a specific user property
  void clearUserProperty(String key) {
    _userProperties.remove(key);
  }

  /// Clear all user properties
  void clearUserProperties() {
    _userProperties.clear();
  }

  /// Get the screen tracker for use with Navigator
  RouteObserver<PageRoute> get screenTracker {
    _screenTracker ??= ScreenTracker(onScreenView: _handleScreenView);
    return _screenTracker!;
  }

  /// Get the go_router compatible screen tracker
  NavigatorObserver get goRouterScreenTracker {
    _goRouterScreenTracker ??= GoRouterScreenTracker(
      onScreenView: _handleScreenView,
    );
    return _goRouterScreenTracker!;
  }

  /// Handle screen view events
  void _handleScreenView(String screenName, String? previousScreen) {
    final now = DateTime.now();

    // Track time spent on previous screen
    if (_currentScreen != null && _screenStartTime != null) {
      final timeSpent = now.difference(_screenStartTime!);
      log(
        'Screen view ended: $_currentScreen',
        level: LogLevel.info,
        type: LogType.analytics,
        metadata: {
          'screen': _currentScreen,
          'timeSpent': timeSpent.inSeconds,
          'nextScreen': screenName,
        },
      );
    }

    // Track new screen view
    _currentScreen = screenName;
    _screenStartTime = now;

    if (_enableDebugLogs) {
      print(
        'Telling: Screen view - $screenName${previousScreen != null ? " (from $previousScreen)" : ""}',
      );
    }

    log(
      'Screen view: $screenName',
      level: LogLevel.info,
      type: LogType.analytics,
      metadata: {
        'screen': screenName,
        if (previousScreen != null) 'previousScreen': previousScreen,
      },
    );
  }

  /// Log a message
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    LogType type = LogType.general,
  }) {
    if (!_initialized) {
      if (_enableDebugLogs) {
        print(
          'Telling SDK not initialized. Call Telling.instance.init() first.',
        );
      }
      return;
    }

    final event = LogEvent(
      type: type,
      level: level,
      message: message,
      timestamp: DateTime.now().toUtc(),
      stackTrace:
          stackTrace?.toString() ??
          (error is Error ? error.stackTrace?.toString() : null),
      metadata:
          metadata, // User properties are sent separately via setUserProperty logs
      deviceMetadata: _deviceMetadata,
      userId: _userId,
      userName: _userName,
      userEmail: _userEmail,
      sessionId: _currentSession?.sessionId,
    );

    // Check rate limiter
    if (!_rateLimiter.shouldSendLog(event)) {
      if (_enableDebugLogs) {
        print('Telling: Rate limited log (${event.level}/${event.type})');
      }
      return; // Drop rate-limited log
    }

    // Enforce buffer size limit - drop oldest logs if full
    if (_buffer.length >= _maxBufferSize) {
      final dropCount = _buffer.length - _bufferTrimSize;
      _buffer.removeRange(0, dropCount);
      if (_enableDebugLogs) {
        print('Telling: Buffer full, dropped $dropCount oldest logs');
      }
    }

    _buffer.add(event);
    _rateLimiter.markLogSent(event);
    _persistLogs(); // Save to disk immediately

    // If error, flush immediately
    if (level == LogLevel.error) {
      _flush();
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());

    // Periodic cleanup for rate limiter
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _rateLimiter.cleanup();
    });
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    // Skip if we've hit permanent failure (e.g., bad API key)
    if (_permanentFailure) {
      if (_enableDebugLogs) {
        print(
          'Telling: Skipping flush due to permanent failure (check API key)',
        );
      }
      return;
    }

    // Check if we should wait before retrying (exponential backoff)
    if (_nextRetryTime != null && DateTime.now().isBefore(_nextRetryTime!)) {
      if (_enableDebugLogs) {
        final waitSeconds = _nextRetryTime!.difference(DateTime.now()).inSeconds;
        print('Telling: Waiting ${waitSeconds}s before retry (backoff)');
      }
      return;
    }

    // Deduplicate buffer by hash before sending
    final uniqueLogs = <String, LogEvent>{};
    for (var log in _buffer) {
      final hash = '${log.message}_${log.level}_${log.stackTrace ?? ""}'
          .hashCode
          .toString();
      uniqueLogs[hash] = log; // Keeps last occurrence
    }

    final eventsToSend = uniqueLogs.values.toList();
    _buffer.clear();

    if (kDebugMode && eventsToSend.length < _buffer.length) {
      if (_enableDebugLogs) {
        print(
          'Telling: Deduplicated buffer: ${_buffer.length} → ${eventsToSend.length} unique logs',
        );
      }
    }

    try {
      // Batch sending
      // if (kDebugMode) {
      //   print('Telling: Sending ${eventsToSend.length} logs to $_baseUrl');
      // }

      final jsonPayload = jsonEncode(
        eventsToSend.map((e) => e.toJson()).toList(),
      );
      final jsonBytes = utf8.encode(jsonPayload);

      // Use gzip compression for payloads > 1KB to reduce network overhead
      final bool useCompression = jsonBytes.length > 1024;
      final List<int> body;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
      };

      if (useCompression) {
        body = gzip.encode(jsonBytes);
        headers['Content-Encoding'] = 'gzip';
        // Compression logging disabled for cleaner output
        // if (_enableDebugLogs) {
        //   final savings = ((1 - body.length / jsonBytes.length) * 100).toStringAsFixed(0);
        //   print('Telling: Compressed ${jsonBytes.length} → ${body.length} bytes ($savings% reduction)');
        // }
      } else {
        body = jsonBytes;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Success! Reset failure counter and backoff
        _consecutiveFailures = 0;
        _nextRetryTime = null;
        _persistLogs();
      } else if (response.statusCode == 403) {
        // Forbidden - likely invalid API key
        _consecutiveFailures++;

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          _permanentFailure = true;
          _buffer.clear(); // Don't retry
          _persistLogs();

          if (_enableDebugLogs) {
            print('━' * 60);
            print('🚨 Telling SDK: INVALID API KEY');
            print('━' * 60);
            print('Your API key is not recognized by the backend.');
            print('');
            print('To fix this:');
            print('1. Create a project in your Telling dashboard');
            print('2. Copy the project API key');
            print('3. Update Telling.instance.init() with the correct key');
            print('');
            print('Current API key: ${_apiKey!.substring(0, 8)}...');
            print('━' * 60);
          }
        } else {
          if (_enableDebugLogs) {
            print(
              'Telling: Invalid API key (attempt $_consecutiveFailures/$_maxConsecutiveFailures)',
            );
          }
          // Don't put back in buffer - discard on 403
          _buffer.clear();
          _persistLogs();
        }
      } else {
        // Other errors - retry with exponential backoff
        _consecutiveFailures++;
        _setBackoff();

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          if (_enableDebugLogs) {
            print(
              'Telling: Giving up after $_maxConsecutiveFailures failures. Status: ${response.statusCode}',
            );
          }
          _consecutiveFailures = 0;
          _nextRetryTime = null;
          // Keep logs in buffer for next app session
        } else {
          if (_enableDebugLogs) {
            final backoffSeconds = _nextRetryTime!.difference(DateTime.now()).inSeconds;
            print(
              'Telling: Failed (${response.statusCode}). Retry $_consecutiveFailures/$_maxConsecutiveFailures in ${backoffSeconds}s',
            );
          }
          _buffer.addAll(eventsToSend); // Retry
        }
        _persistLogs();
      }
    } catch (e) {
      _consecutiveFailures++;
      _setBackoff();

      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        if (_enableDebugLogs) {
          print(
            'Telling: Connection issue, giving up after $_consecutiveFailures attempts. Logs persisted.',
          );
        }
        _consecutiveFailures = 0;
        _nextRetryTime = null;
        // Keep logs in buffer for next app session
      } else {
        if (_enableDebugLogs) {
          final backoffSeconds = _nextRetryTime!.difference(DateTime.now()).inSeconds;
          print(
            'Telling: Connection issue. Retry $_consecutiveFailures/$_maxConsecutiveFailures in ${backoffSeconds}s',
          );
        }
        _buffer.addAll(eventsToSend); // Retry
      }
      _persistLogs();
    }
  }

  /// Calculate exponential backoff: 5s, 10s, 20s, 40s, 80s
  void _setBackoff() {
    final backoffSeconds = 5 * (1 << (_consecutiveFailures - 1)); // 5, 10, 20, 40, 80
    _nextRetryTime = DateTime.now().add(Duration(seconds: backoffSeconds));
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _buffer.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, logsJson);
    } catch (e) {
      if (_enableDebugLogs) {
        print('Telling: Failed to persist logs: $e');
      }
    }
  }

  Future<void> _loadPersistedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_storageKey);

      if (logsJson != null && logsJson.isNotEmpty) {
        if (_enableDebugLogs) {
          print('Telling: Found ${logsJson.length} unsent logs on disk.');
        }
        for (var logString in logsJson) {
          try {
            final map = jsonDecode(logString) as Map<String, dynamic>;
            final event = LogEvent.fromJson(map);
            _buffer.add(event);
          } catch (e) {
            if (_enableDebugLogs) {
              print('Telling: Error parsing persisted log: $e');
            }
          }
        }
        // Try to send immediately
        _flush();
      }
    } catch (e) {
      if (_enableDebugLogs) {
        print('Telling: Failed to load persisted logs: $e');
      }
    }
  }

  // ===== Session Management =====

  /// Start a new session
  void _startNewSession() {
    _currentSession = Session(
      sessionId: _generateSessionId(),
      startTime: DateTime.now(),
      userId: _userId,
      userEmail: _userEmail,
      userName: _userName,
    );

    if (_enableDebugLogs) {
      print('Telling: Started session ${_currentSession!.sessionId}');
    }

    // Track session start event
    log(
      'Session started',
      level: LogLevel.info,
      type: LogType.analytics,
      metadata: {
        'sessionId': _currentSession!.sessionId,
        'startTime': _currentSession!.startTime.toIso8601String(),
      },
    );
  }

  /// End the current session
  void _endSession() {
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession!.endTime = DateTime.now();

      if (_enableDebugLogs) {
        print(
          'Telling: Ended session ${_currentSession!.sessionId} (duration: ${_currentSession!.duration?.inSeconds}s)',
        );
      }

      // Track session end event
      log(
        'Session ended',
        level: LogLevel.info,
        type: LogType.analytics,
        metadata: _currentSession!.toJson(),
      );

      // Flush logs immediately
      _flush();
    }
  }

  DateTime? _lastBackgroundTime;
  static const Duration _sessionTimeout = Duration(minutes: 5);

  void _onAppPaused() {
    _lastBackgroundTime = DateTime.now();
    _flush(); // Ensure logs are sent before potential OS kill
  }

  void _onAppResumed() {
    if (_lastBackgroundTime != null) {
      final timeInBackground = DateTime.now().difference(_lastBackgroundTime!);

      if (timeInBackground > _sessionTimeout) {
        // Session timed out - end old one and start new one
        if (_enableDebugLogs) {
          print(
            'Telling: Session timed out (${timeInBackground.inMinutes}m). Starting new session.',
          );
        }
        _endSession();
        _startNewSession();
      } else {
        // Continue current session
        if (_enableDebugLogs) {
          print(
            'Telling: Resuming session (backgrounded for ${timeInBackground.inSeconds}s)',
          );
        }
      }
      _lastBackgroundTime = null;
    } else {
      // Should not happen usually, but safe fallback
      if (_currentSession == null) {
        _startNewSession();
      }
    }
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userPrefix = _userId ?? 'anon';
    return '${userPrefix}_$timestamp';
  }

  /// Setup app lifecycle listeners for session tracking
  void _setupAppLifecycleListeners() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(
        onPause: _onAppPaused,
        onResume: _onAppResumed,
        onDetach: _endSession, // End session immediately on detach
      ),
    );
  }

  void dispose() {
    _flushTimer?.cancel();
  }
}

/// Observer for app lifecycle changes to manage sessions
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDetach;

  _AppLifecycleObserver({
    required this.onPause,
    required this.onResume,
    required this.onDetach,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      onPause();
    } else if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.detached) {
      onDetach();
    }
  }
}
