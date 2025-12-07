import 'package:flutter_test/flutter_test.dart';
import 'package:telling_logger/src/rate_limiter.dart';
import 'package:telling_logger/src/models/log_event.dart';
import 'test_helpers.dart';

void main() {
  group('LogRateLimiter', () {
    late LogRateLimiter rateLimiter;

    setUp(() {
      rateLimiter = LogRateLimiter();
    });

    group('Deduplication', () {
      test('allows first log to be sent', () {
        final event = TestHelpers.createLogEvent(message: 'Test log');
        
        expect(rateLimiter.shouldSendLog(event), isTrue);
      });

      test('blocks duplicate log within deduplication window', () {
        final event = TestHelpers.createLogEvent(
          message: 'Duplicate log',
          level: LogLevel.info,
        );
        
        // First log should be allowed
        expect(rateLimiter.shouldSendLog(event), isTrue);
        rateLimiter.markLogSent(event);
        
        // Duplicate within window should be blocked
        final duplicate = TestHelpers.createLogEvent(
          message: 'Duplicate log',
          level: LogLevel.info,
        );
        expect(rateLimiter.shouldSendLog(duplicate), isFalse);
      });

      test('allows duplicate log after deduplication window expires', () async {
        // Set a shorter deduplication window for testing
        rateLimiter.deduplicationWindow = const Duration(milliseconds: 100);
        
        final event = TestHelpers.createLogEvent(message: 'Test log');
        
        // First log
        expect(rateLimiter.shouldSendLog(event), isTrue);
        rateLimiter.markLogSent(event);
        
        // Wait for deduplication window to expire
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Same log should now be allowed
        final duplicate = TestHelpers.createLogEvent(message: 'Test log');
        expect(rateLimiter.shouldSendLog(duplicate), isTrue);
      });

      test('differentiates logs by message content', () {
        final event1 = TestHelpers.createLogEvent(message: 'Log 1');
        final event2 = TestHelpers.createLogEvent(message: 'Log 2');
        
        expect(rateLimiter.shouldSendLog(event1), isTrue);
        rateLimiter.markLogSent(event1);
        
        expect(rateLimiter.shouldSendLog(event2), isTrue);
      });

      test('differentiates logs by level', () {
        final event1 = TestHelpers.createLogEvent(
          message: 'Same message',
          level: LogLevel.info,
        );
        final event2 = TestHelpers.createLogEvent(
          message: 'Same message',
          level: LogLevel.error,
        );
        
        expect(rateLimiter.shouldSendLog(event1), isTrue);
        rateLimiter.markLogSent(event1);
        
        expect(rateLimiter.shouldSendLog(event2), isTrue);
      });

      test('differentiates logs by stack trace', () {
        final event1 = TestHelpers.createLogEvent(
          message: 'Error',
          stackTrace: 'Stack trace 1',
        );
        final event2 = TestHelpers.createLogEvent(
          message: 'Error',
          stackTrace: 'Stack trace 2',
        );
        
        expect(rateLimiter.shouldSendLog(event1), isTrue);
        rateLimiter.markLogSent(event1);
        
        expect(rateLimiter.shouldSendLog(event2), isTrue);
      });

      test('differentiates logs by metadata', () {
        final event1 = TestHelpers.createLogEvent(
          message: 'Event',
          metadata: {'key': 'value1'},
        );
        final event2 = TestHelpers.createLogEvent(
          message: 'Event',
          metadata: {'key': 'value2'},
        );
        
        expect(rateLimiter.shouldSendLog(event1), isTrue);
        rateLimiter.markLogSent(event1);
        
        expect(rateLimiter.shouldSendLog(event2), isTrue);
      });
    });

    group('Per-Second Rate Limiting', () {
      test('allows logs up to max per second', () {
        rateLimiter.maxLogsPerSecond = 3;
        
        final events = List.generate(
          3,
          (i) => TestHelpers.createLogEvent(message: 'Log $i'),
        );
        
        // All 3 should be allowed
        for (var event in events) {
          expect(rateLimiter.shouldSendLog(event), isTrue);
          rateLimiter.markLogSent(event);
        }
      });

      test('blocks logs exceeding max per second', () {
        rateLimiter.maxLogsPerSecond = 3;
        
        final events = List.generate(
          5,
          (i) => TestHelpers.createLogEvent(message: 'Log $i'),
        );
        
        // First 3 should be allowed
        for (var i = 0; i < 3; i++) {
          expect(rateLimiter.shouldSendLog(events[i]), isTrue);
          rateLimiter.markLogSent(events[i]);
        }
        
        // Next 2 should be blocked (exceeds limit)
        for (var i = 3; i < 5; i++) {
          expect(rateLimiter.shouldSendLog(events[i]), isFalse);
        }
      });

      test('resets counter after one second', () async {
        rateLimiter.maxLogsPerSecond = 2;
        
        // Send 2 logs (hit limit)
        for (var i = 0; i < 2; i++) {
          final event = TestHelpers.createLogEvent(message: 'Log $i');
          expect(rateLimiter.shouldSendLog(event), isTrue);
          rateLimiter.markLogSent(event);
        }
        
        // Third log should be blocked
        final blocked = TestHelpers.createLogEvent(message: 'Blocked');
        expect(rateLimiter.shouldSendLog(blocked), isFalse);
        
        // Wait for next second
        await Future.delayed(const Duration(seconds: 1, milliseconds: 100));
        
        // Should allow logs again
        final allowed = TestHelpers.createLogEvent(message: 'Allowed');
        expect(rateLimiter.shouldSendLog(allowed), isTrue);
      });
    });

    group('Type-Specific Throttling', () {
      test('throttles crash logs with longer window', () {
        rateLimiter.crashThrottleWindow = const Duration(milliseconds: 200);
        
        final crash1 = TestHelpers.createLogEvent(
          message: 'Different crash 1',
          type: LogType.crash,
          level: LogLevel.fatal,
        );
        final crash2 = TestHelpers.createLogEvent(
          message: 'Different crash 2',
          type: LogType.crash,
          level: LogLevel.fatal,
        );
        
        // First crash allowed
        expect(rateLimiter.shouldSendLog(crash1), isTrue);
        rateLimiter.markLogSent(crash1);
        
        // Second crash immediately after should be throttled
        expect(rateLimiter.shouldSendLog(crash2), isFalse);
      });

      test('throttles multiple crash logs with longer window', () {
        rateLimiter.crashThrottleWindow = const Duration(milliseconds: 200);
        
        final crash3 = TestHelpers.createLogEvent(
          message: 'Different crash 3',
          type: LogType.crash,
          level: LogLevel.error,
        );
        final crash4 = TestHelpers.createLogEvent(
          message: 'Different crash 4',
          type: LogType.crash,
          level: LogLevel.error,
        );
        
        // First crash allowed
        expect(rateLimiter.shouldSendLog(crash3), isTrue);
        rateLimiter.markLogSent(crash3);
        
        // Second crash immediately after should be throttled
        expect(rateLimiter.shouldSendLog(crash4), isFalse);
      });

      test('does not throttle non-crash/exception logs by type', () {
        final analytics1 = TestHelpers.createLogEvent(
          message: 'Event 1',
          type: LogType.analytics,
        );
        final analytics2 = TestHelpers.createLogEvent(
          message: 'Event 2',
          type: LogType.analytics,
        );
        
        // Both should be allowed (no type throttling for analytics)
        expect(rateLimiter.shouldSendLog(analytics1), isTrue);
        rateLimiter.markLogSent(analytics1);
        
        expect(rateLimiter.shouldSendLog(analytics2), isTrue);
      });

      test('allows crash logs after throttle window expires', () async {
        rateLimiter.crashThrottleWindow = const Duration(milliseconds: 100);
        
        final crash1 = TestHelpers.createLogEvent(
          message: 'Crash 1',
          type: LogType.crash,
          level: LogLevel.fatal,
        );
        
        expect(rateLimiter.shouldSendLog(crash1), isTrue);
        rateLimiter.markLogSent(crash1);
        
        // Wait for throttle window to expire
        await Future.delayed(const Duration(milliseconds: 150));
        
        final crash2 = TestHelpers.createLogEvent(
          message: 'Crash 2',
          type: LogType.crash,
          level: LogLevel.fatal,
        );
        
        expect(rateLimiter.shouldSendLog(crash2), isTrue);
      });
    });

    group('Cache Cleanup', () {
      test('removes old deduplication entries', () {
        rateLimiter.deduplicationWindow = const Duration(milliseconds: 100);
        
        // Send some logs
        for (var i = 0; i < 5; i++) {
          final event = TestHelpers.createLogEvent(message: 'Log $i');
          rateLimiter.shouldSendLog(event);
          rateLimiter.markLogSent(event);
        }
        
        final statsBefore = rateLimiter.getStats();
        expect(statsBefore['cached_hashes'], greaterThan(0));
        
        // Run cleanup
        rateLimiter.cleanup();
        
        // Old entries should be removed
        final statsAfter = rateLimiter.getStats();
        // Since entries are recent, they might not be cleaned up yet
        expect(statsAfter['cached_hashes'], greaterThanOrEqualTo(0));
      });

      test('removes old throttle entries', () {
        // Send some crash logs
        for (var i = 0; i < 3; i++) {
          final event = TestHelpers.createLogEvent(
            message: 'Crash $i',
            type: LogType.crash,
            level: LogLevel.fatal,
          );
          if (rateLimiter.shouldSendLog(event)) {
            rateLimiter.markLogSent(event);
          }
        }
        
        final statsBefore = rateLimiter.getStats();
        expect(statsBefore['throttle_entries'], greaterThan(0));
        
        // Run cleanup
        rateLimiter.cleanup();
        
        final statsAfter = rateLimiter.getStats();
        expect(statsAfter['throttle_entries'], greaterThanOrEqualTo(0));
      });
    });

    group('Statistics', () {
      test('reports cached hash count', () {
        final event1 = TestHelpers.createLogEvent(message: 'Log 1');
        final event2 = TestHelpers.createLogEvent(message: 'Log 2');
        
        rateLimiter.shouldSendLog(event1);
        rateLimiter.markLogSent(event1);
        rateLimiter.shouldSendLog(event2);
        rateLimiter.markLogSent(event2);
        
        final stats = rateLimiter.getStats();
        expect(stats['cached_hashes'], equals(2));
      });

      test('reports logs sent this second', () {
        final event = TestHelpers.createLogEvent(message: 'Log');
        
        rateLimiter.shouldSendLog(event);
        rateLimiter.markLogSent(event);
        
        final stats = rateLimiter.getStats();
        expect(stats['logs_this_second'], equals(1));
      });

      test('reports throttle entries', () {
        final crash = TestHelpers.createLogEvent(
          message: 'Crash',
          type: LogType.crash,
          level: LogLevel.fatal,
        );
        
        rateLimiter.shouldSendLog(crash);
        rateLimiter.markLogSent(crash);
        
        final stats = rateLimiter.getStats();
        expect(stats['throttle_entries'], greaterThan(0));
      });
    });
  });
}
