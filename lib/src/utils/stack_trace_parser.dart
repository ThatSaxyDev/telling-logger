/// Stack trace parsing utilities inspired by Firebase Crashlytics.
///
/// Uses the `stack_trace` package to parse raw Dart stack traces into
/// structured elements for better crash grouping and dashboard display.
library;

import 'package:stack_trace/stack_trace.dart';

/// Regex to detect obfuscated stack trace lines (release builds).
final _obfuscatedStackTraceLineRegExp =
    RegExp(r'^(\s*#\d{2} abs )([\da-f]+)((?:virt [\da-f]+)?(?: .*)?)$');

/// A single parsed stack frame.
class StackFrame {
  final String file;
  final int line;
  final int? column;
  final String method;
  final String? className;

  const StackFrame({
    required this.file,
    required this.line,
    this.column,
    required this.method,
    this.className,
  });

  Map<String, String> toJson() {
    return {
      'file': file,
      'line': line.toString(),
      if (column != null) 'column': column.toString(),
      'method': method,
      if (className != null) 'class': className!,
    };
  }
}

/// Parses a [StackTrace] into a list of structured [StackFrame] elements.
///
/// Uses the `stack_trace` package's [Trace.parseVM] for robust parsing,
/// matching Firebase Crashlytics' approach.
List<StackFrame> parseStackTrace(StackTrace stackTrace) {
  final Trace trace = Trace.parseVM(stackTrace.toString()).terse;
  final frames = <StackFrame>[];

  for (final Frame frame in trace.frames) {
    if (frame is UnparsedFrame) {
      // Handle obfuscated traces (release builds)
      if (_obfuscatedStackTraceLineRegExp.hasMatch(frame.member)) {
        frames.add(StackFrame(
          file: '',
          line: 0,
          method: frame.member,
        ));
      }
      // Skip other unparsed frames (like async gaps)
    } else {
      // Parse class.method into separate fields
      final String member = frame.member ?? '<fn>';
      String? className;
      String methodName;

      final dotIndex = member.lastIndexOf('.');
      if (dotIndex > 0) {
        className = member.substring(0, dotIndex);
        methodName = member.substring(dotIndex + 1);
      } else {
        methodName = member;
      }

      frames.add(StackFrame(
        file: frame.library,
        line: frame.line ?? 0,
        column: frame.column,
        method: methodName,
        className: className,
      ));
    }
  }

  return frames;
}

/// Converts a list of [StackFrame] to JSON-serializable format.
List<Map<String, String>> stackFramesToJson(List<StackFrame> frames) {
  return frames.map((f) => f.toJson()).toList();
}
