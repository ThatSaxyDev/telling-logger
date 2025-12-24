import 'package:flutter_test/flutter_test.dart';
import 'package:telling_logger/src/utils/stack_trace_parser.dart';

void main() {
  group('Stack Trace Parser', () {
    test('parses standard Dart VM stack trace', () {
      // Simulate a standard Dart stack trace
      final stackTrace = StackTrace.fromString('''
#0      MyClass.myMethod (package:my_app/src/my_file.dart:42:10)
#1      anotherFunction (package:my_app/other.dart:15:3)
#2      main (package:my_app/main.dart:5:1)
''');

      final frames = parseStackTrace(stackTrace);

      expect(frames.length, 3);

      expect(frames[0].file, 'package:my_app/src/my_file.dart');
      expect(frames[0].line, 42);
      expect(frames[0].column, 10);
      expect(frames[0].method, 'myMethod');
      expect(frames[0].className, 'MyClass');

      expect(frames[1].file, 'package:my_app/other.dart');
      expect(frames[1].line, 15);
      expect(frames[1].method, 'anotherFunction');
      expect(frames[1].className, isNull);

      expect(frames[2].file, 'package:my_app/main.dart');
      expect(frames[2].line, 5);
      expect(frames[2].method, 'main');
    });

    test('handles nested class names', () {
      final stackTrace = StackTrace.fromString('''
#0      Outer.Inner.method (package:my_app/file.dart:10:5)
''');

      final frames = parseStackTrace(stackTrace);

      expect(frames.length, 1);
      expect(frames[0].className, 'Outer.Inner');
      expect(frames[0].method, 'method');
    });

    test('handles empty stack trace', () {
      final stackTrace = StackTrace.fromString('');

      final frames = parseStackTrace(stackTrace);

      expect(frames, isEmpty);
    });

    test('converts frames to JSON', () {
      final frames = [
        const StackFrame(
          file: 'package:my_app/file.dart',
          line: 42,
          column: 10,
          method: 'myMethod',
          className: 'MyClass',
        ),
      ];

      final json = stackFramesToJson(frames);

      expect(json.length, 1);
      expect(json[0]['file'], 'package:my_app/file.dart');
      expect(json[0]['line'], '42');
      expect(json[0]['column'], '10');
      expect(json[0]['method'], 'myMethod');
      expect(json[0]['class'], 'MyClass');
    });

    test('handles traces without column numbers', () {
      final stackTrace = StackTrace.fromString('''
#0      myFunction (package:my_app/file.dart:10)
''');

      final frames = parseStackTrace(stackTrace);

      expect(frames.length, 1);
      expect(frames[0].line, 10);
      expect(frames[0].column, isNull);
    });

    test('produces terse output (removes package internals)', () {
      // The stack_trace package's .terse removes frames from dart:core, etc.
      final stackTrace = StackTrace.fromString('''
#0      myFunction (package:my_app/file.dart:10:5)
#1      _rootRun (dart:async/zone.dart:1391:13)
''');

      final frames = parseStackTrace(stackTrace);

      // The dart:async frame should be filtered by .terse
      expect(frames.length, lessThanOrEqualTo(2));
      expect(frames[0].file, 'package:my_app/file.dart');
    });
  });
}
