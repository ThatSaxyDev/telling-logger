import 'package:flutter_test/flutter_test.dart';
import 'package:telling_logger/src/models/session.dart';
import '../test_helpers.dart';

void main() {
  group('Session', () {
    group('Session Creation', () {
      test('creates session with all required fields', () {
        final session = TestHelpers.createSession(
          sessionId: 'session_123',
          userId: 'user_456',
          userName: 'John Doe',
          userEmail: 'john@example.com',
        );

        expect(session.sessionId, equals('session_123'));
        expect(session.userId, equals('user_456'));
        expect(session.userName, equals('John Doe'));
        expect(session.userEmail, equals('john@example.com'));
        expect(session.startTime, isNotNull);
        expect(session.endTime, isNull);
      });

      test('creates session with minimal fields', () {
        final session = TestHelpers.createSession();

        expect(session.sessionId, isNotEmpty);
        expect(session.userId, isNull);
        expect(session.userName, isNull);
        expect(session.userEmail, isNull);
      });

      test('generates correct session ID format', () {
        final session = Session(
          sessionId: 'user_123_1700000000',
          startTime: DateTime.now(),
        );

        expect(session.sessionId, contains('_'));
      });
    });

    group('Session State', () {
      test('isActive returns true for ongoing session', () {
        final session = TestHelpers.createSession();

        expect(session.isActive, isTrue);
        expect(session.endTime, isNull);
      });

      test('isActive returns false for ended session', () {
        final session = TestHelpers.createSession(
          endTime: DateTime.now(),
        );

        expect(session.isActive, isFalse);
        expect(session.endTime, isNotNull);
      });
    });

    group('Session Duration', () {
      test('calculates duration for ongoing session', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 5));
        final session = TestHelpers.createSession(startTime: startTime);

        final duration = session.duration;
        expect(duration, isNotNull);
        expect(duration!.inMinutes, greaterThanOrEqualTo(4)); // Allow some margin
      });

      test('calculates exact duration for ended session', () {
        final startTime = DateTime.now().subtract(const Duration(hours: 1));
        final endTime = DateTime.now();
        final session = TestHelpers.createSession(
          startTime: startTime,
          endTime: endTime,
        );

        final duration = session.duration;
        expect(duration, isNotNull);
        expect(duration!.inMinutes, greaterThanOrEqualTo(59)); // ~1 hour
      });

      test('duration updates for ongoing session', () async {
        final session = TestHelpers.createSession();

        final duration1 = session.duration;
        await Future.delayed(const Duration(milliseconds: 100));
        final duration2 = session.duration;

        expect(duration2, greaterThan(duration1!));
      });
    });

    group('Session JSON Serialization', () {
      test('toJson includes all fields', () {
        final startTime = DateTime(2024, 1, 1, 12, 0);
        final endTime = DateTime(2024, 1, 1, 13, 0);
        
        final session = Session(
          sessionId: 'session_123',
          startTime: startTime,
          endTime: endTime,
          userId: 'user_456',
          userName: 'John Doe',
          userEmail: 'john@example.com',
        );

        final json = session.toJson();

        expect(json['sessionId'], equals('session_123'));
        expect(json['startTime'], equals(startTime.toIso8601String()));
        expect(json['endTime'], equals(endTime.toIso8601String()));
        expect(json['userId'], equals('user_456'));
        expect(json['userName'], equals('John Doe'));
        expect(json['userEmail'], equals('john@example.com'));
        expect(json['durationSeconds'], equals(3600)); // 1 hour
        expect(json['isActive'], isFalse);
      });

      test('toJson handles null optional fields', () {
        final session = TestHelpers.createSession();

        final json = session.toJson();

        expect(json['sessionId'], isNotNull);
        expect(json['startTime'], isNotNull);
        expect(json['userId'], isNull);
        expect(json['userName'], isNull);
        expect(json['userEmail'], isNull);
        expect(json['isActive'], isTrue);
      });

      test('toJson includes null endTime for ongoing session', () {
        final session = TestHelpers.createSession();

        final json = session.toJson();

        expect(json['endTime'], isNull);
        expect(json['isActive'], isTrue);
      });
    });

    group('Session Timeout Behavior', () {
      test('represents typical 5-minute timeout scenario', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 6));
        final session = TestHelpers.createSession(startTime: startTime);

        // Session lasted more than 5 minutes
        expect(session.duration!.inMinutes, greaterThanOrEqualTo(5));
        expect(session.isActive, isTrue); // Still active, SDK would end it
      });

      test('session within timeout window', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 3));
        final session = TestHelpers.createSession(startTime: startTime);

        // Session within 5-minute window
        expect(session.duration!.inMinutes, lessThan(5));
        expect(session.isActive, isTrue);
      });
    });

    group('Session Lifecycle', () {
      test('can end an active session', () {
        final session = TestHelpers.createSession();

        expect(session.isActive, isTrue);

        // Simulate ending session
        session.endTime = DateTime.now();

        expect(session.isActive, isFalse);
        expect(session.endTime, isNotNull);
      });

      test('session duration remains stable after ending', () async {
        final session = TestHelpers.createSession();

        // End session
        session.endTime = DateTime.now();
        final duration1 = session.duration;

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Duration should not change for ended session
        final duration2 = session.duration;
        expect(duration2, equals(duration1));
      });
    });
  });
}
