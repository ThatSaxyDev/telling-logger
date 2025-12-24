/// Test script to visualize what the SDK sends for stack traces.
///
/// Run with: dart run test/preview_stack_trace_output.dart
library;

import 'dart:convert';
import 'package:telling_logger/src/utils/stack_trace_parser.dart';
import 'package:telling_logger/src/models/log_event.dart';

void main() {
  print('=' * 60);
  print('STRUCTURED STACK TRACE PREVIEW');
  print('=' * 60);

  // Simulate an exception with a stack trace
  try {
    _level1();
  } catch (e, stack) {
    print('\n📌 RAW STACK TRACE:');
    print('-' * 40);
    print(stack.toString());

    print('\n📌 PARSED FRAMES:');
    print('-' * 40);
    final frames = parseStackTrace(stack);
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      final className = f.className != null ? '${f.className}.' : '';
      print('#$i  $className${f.method}');
      print('    📁 ${f.file}:${f.line}${f.column != null ? ':${f.column}' : ''}');
    }

    print('\n📌 JSON OUTPUT (what gets sent to server):');
    print('-' * 40);
    final jsonFrames = stackFramesToJson(frames);
    const encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(jsonFrames));

    print('\n📌 FULL LOG EVENT:');
    print('-' * 40);
    final event = LogEvent(
      level: LogLevel.error,
      message: 'Test exception: $e',
      timestamp: DateTime.now().toUtc(),
      stackTrace: stack.toString(),
      stackTraceElements: jsonFrames,
      metadata: {'context': 'test'},
    );
    print(encoder.convert(event.toJson()));
  }

  print('\n${'=' * 60}');
  print('✅ This is what the SDK now sends to the server!');
  print('=' * 60);
}

// Helper functions to create a real stack trace
void _level1() => _level2();
void _level2() => _level3();
void _level3() => throw Exception('Test error for stack trace demo');
