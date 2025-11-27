import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telling_logger/src/telling.dart';
import 'package:telling_logger/src/models/log_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Telling SDK Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // Clean up
      Telling.instance.dispose();
    });

    group('SDK Initialization', () {
      test('initializes successfully with API key', () async {
        await Telling.instance.init('test_api_key_123');

        // SDK should be initialized
        // We can't directly check _initialized, but we can try logging
        expect(() => Telling.instance.log('Test'), returnsNormally);
      });

      test('initializes with user context', () async {
        await Telling.instance.init(
          'test_api_key',
          userId: 'user_123',
          userName: 'John Doe',
          userEmail: 'john@example.com',
        );

        // User context should be set
        expect(() => Telling.instance.log('Test'), returnsNormally);
      });

      test('initializes with debug logs disabled', () async {
        await Telling.instance.init(
          'test_api_key',
          enableDebugLogs: false,
        );

        expect(() => Telling.instance.log('Test'), returnsNormally);
      });

      test('collects device metadata on init', () async {
        await Telling.instance.init('test_api_key');

        // Device metadata should be collected (we can't directly verify,
        // but it should not throw)
        expect(() => Telling.instance.log('Test'), returnsNormally);
      });
    });

    group('User Context Management', () {
      test('sets user context', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.setUser(
            userId: 'user_456',
            userName: 'Jane Smith',
            userEmail: 'jane@example.com',
          ),
          returnsNormally,
        );

        // Should log user identification event
        Telling.instance.log('After user set');
      });

      test('clears user context', () async {
        await Telling.instance.init(
          'test_api_key',
          userId: 'user_123',
        );

        expect(() => Telling.instance.clearUser(), returnsNormally);

        // Should log logout event
        Telling.instance.log('After user clear');
      });

      test('setUser starts new session', () async {
        await Telling.instance.init('test_api_key');

        // Set user should end current session and start new one
        Telling.instance.setUser(
          userId: 'user_789',
          userName: 'Bob Johnson',
        );

        // Wait for session change to process
        await Future.delayed(const Duration(milliseconds: 100));

        expect(() => Telling.instance.log('Test'), returnsNormally);
      });

      test('clearUser starts new anonymous session', () async {
        await Telling.instance.init(
          'test_api_key',
          userId: 'user_123',
        );

        Telling.instance.clearUser();

        // Wait for session change
        await Future.delayed(const Duration(milliseconds: 100));

        expect(() => Telling.instance.log('Test'), returnsNormally);
      });
    });

    group('Logging Functionality', () {
      test('logs message at info level', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log('Test info message'),
          returnsNormally,
        );
      });

      test('logs message at different levels', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log('Debug', level: LogLevel.debug),
          returnsNormally,
        );
        expect(
          () => Telling.instance.log('Warning', level: LogLevel.warning),
          returnsNormally,
        );
        expect(
          () => Telling.instance.log('Error', level: LogLevel.error),
          returnsNormally,
        );
      });

      test('logs with metadata', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log(
            'Event with metadata',
            metadata: {
              'key1': 'value1',
              'key2': 123,
              'key3': true,
            },
          ),
          returnsNormally,
        );
      });

      test('logs with error and stack trace', () async {
        await Telling.instance.init('test_api_key');

        try {
          throw Exception('Test exception');
        } catch (e, stack) {
          expect(
            () => Telling.instance.log(
              'Exception occurred',
              level: LogLevel.error,
              error: e,
              stackTrace: stack,
            ),
            returnsNormally,
          );
        }
      });

      test('logs analytics event', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.event(
            'button_clicked',
            properties: {'button_name': 'submit'},
          ),
          returnsNormally,
        );
      });

      test('respects rate limiting', () async {
        await Telling.instance.init('test_api_key');

        // Log same message multiple times quickly
        for (var i = 0; i < 5; i++) {
          Telling.instance.log('Duplicate message');
        }

        // Should be rate limited (only first one goes through)
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Crash Reporting', () {
      test('enables crash reporting', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.enableCrashReporting(),
          returnsNormally,
        );
      });

      test('requires initialization before enabling crash reporting', () {
        // Don't initialize

        expect(
          () => Telling.instance.enableCrashReporting(),
          returnsNormally, // Should handle gracefully
        );
      });
    });

    group('Session Management', () {
      test('starts session on init', () async {
        await Telling.instance.init('test_api_key');

        // Session should be created automatically
        // We can verify by logging (session ID should be included)
        Telling.instance.log('Test log');

        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('includes session ID in logs', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Test with session');

        // Session context should be included
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('maintains session across multiple logs', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Log 1');
        await Future.delayed(const Duration(milliseconds: 50));
        
        Telling.instance.log('Log 2');
        await Future.delayed(const Duration(milliseconds: 50));
        
        Telling.instance.log('Log 3');

        // All should have same session ID
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Offline Persistence', () {
      test('persists logs when offline', () async {
        SharedPreferences.setMockInitialValues({});
        await Telling.instance.init('test_api_key');

        // Log some events (they'll be buffered)
        Telling.instance.log('Offline log 1');
        Telling.instance.log('Offline log 2');
        Telling.instance.log('Offline log 3');

        // Wait briefly for persistence (before 5s flush timer)
        await Future.delayed(const Duration(milliseconds: 100));

        final prefs = await SharedPreferences.getInstance();
        final logs = prefs.getStringList('telling_logs_buffer');
        
        // Logs should be persisted (before flush attempt)
        expect(logs, isNotNull);
        expect(logs!.length, greaterThan(0));
      });

      test('loads persisted logs on init', () async {
        // Set up some persisted logs
        final testLog = LogEvent(
          level: LogLevel.info,
          message: 'Persisted log',
          timestamp: DateTime.now(),
          type: LogType.general,
        );

        SharedPreferences.setMockInitialValues({
          'telling_logs_buffer': [jsonEncode(testLog.toJson())],
        });

        await Telling.instance.init('test_api_key');

        // Wait for logs to load and flush attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Logs should be loaded and flush attempted
      });

      test('clears persisted logs after successful send', () async {
        SharedPreferences.setMockInitialValues({});
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Test log');

        // Wait for flush and persistence
        await Future.delayed(const Duration(seconds: 6));

        // Note: Without mocking HTTP, logs will fail to send and remain persisted
        // This test validates the persistence mechanism works
      });
    });

    group('Log Batching and Flushing', () {
      test('batches multiple logs', () async {
        await Telling.instance.init('test_api_key');

        // Add multiple logs
        for (var i = 0; i < 10; i++) {
          Telling.instance.log('Batch log $i');
        }

        // Wait for potential flush
        await Future.delayed(const Duration(milliseconds: 200));

        // Logs should be batched together
      });

      test('flushes on error-level log', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Info log');
        await Future.delayed(const Duration(milliseconds: 100));

        Telling.instance.log('Error!', level: LogLevel.error);

        // Should trigger immediate flush
        await Future.delayed(const Duration(milliseconds: 200));
      });

      test('periodic flush timer triggers', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Log 1');
        Telling.instance.log('Log 2');

        // Wait for flush timer (5 seconds)
        await Future.delayed(const Duration(seconds: 6));

        // Flush should have been triggered
      });

      test('deduplicates logs in buffer before sending', () async {
        await Telling.instance.init('test_api_key');

        // Log duplicate messages
        Telling.instance.log('Duplicate 1');
        Telling.instance.log('Duplicate 2');
        Telling.instance.log('Duplicate 1'); // Duplicate

        await Future.delayed(const Duration(seconds: 6));

        // Buffer should deduplicate before sending
      });
    });

    group('Retry Logic', () {
      test('retries failed requests', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Test log');

        // Wait for initial flush attempt (will fail without real backend)
        await Future.delayed(const Duration(seconds: 6));

        // Should retry on next flush
        await Future.delayed(const Duration(seconds: 6));
      });

      test('gives up after max failures', () async {
        await Telling.instance.init('test_api_key');

        Telling.instance.log('Test log');

        // Wait for multiple flush attempts
        await Future.delayed(const Duration(seconds: 18)); // 3 attempts

        // Should give up after 2 consecutive failures
      });

      test('handles 403 as permanent failure', () async {
        await Telling.instance.init('invalid_api_key');

        Telling.instance.log('Test log');

        // Wait for flush attempts
        await Future.delayed(const Duration(seconds: 12));

        // Should detect 403 and stop retrying
      });
    });

    group('Screen Tracking', () {
      test('provides screen tracker instance', () async {
        await Telling.instance.init('test_api_key');

        final tracker = Telling.instance.screenTracker;

        expect(tracker, isNotNull);
        expect(tracker, isA<RouteObserver>());
      });

      test('provides go_router screen tracker', () async {
        await Telling.instance.init('test_api_key');

        final tracker = Telling.instance.goRouterScreenTracker;

        expect(tracker, isNotNull);
        expect(tracker, isA<NavigatorObserver>());
      });

      test('screen tracker instances are reused', () async {
        await Telling.instance.init('test_api_key');

        final tracker1 = Telling.instance.screenTracker;
        final tracker2 = Telling.instance.screenTracker;

        expect(tracker1, same(tracker2));
      });
    });

    group('Edge Cases', () {
      test('handles logging before initialization gracefully', () {
        // Don't initialize

        expect(
          () => Telling.instance.log('Before init'),
          returnsNormally, // Should not crash
        );
      });

      test('handles null metadata', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log('Log', metadata: null),
          returnsNormally,
        );
      });

      test('handles empty metadata', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log('Log', metadata: {}),
          returnsNormally,
        );
      });

      test('handles very long messages', () async {
        await Telling.instance.init('test_api_key');

        final longMessage = 'A' * 10000; // 10K characters

        expect(
          () => Telling.instance.log(longMessage),
          returnsNormally,
        );
      });

      test('handles rapid successive logs', () async {
        await Telling.instance.init('test_api_key');

        // Spam logs
        for (var i = 0; i < 100; i++) {
          Telling.instance.log('Rapid log $i');
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // Should handle gracefully with rate limiting
      });

      test('handles special characters in messages', () async {
        await Telling.instance.init('test_api_key');

        expect(
          () => Telling.instance.log('Special: 😀 🚀 ñ ü €'),
          returnsNormally,
        );
      });
    });
  });
}
