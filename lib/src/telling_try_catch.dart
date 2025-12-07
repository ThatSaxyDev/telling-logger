import 'package:flutter/foundation.dart';
import 'telling.dart';

/// A mixin that provides convenient try-catch wrappers with automatic
/// exception reporting to Telling.
///
/// Use this mixin in your classes to easily wrap async operations with
/// automatic error capture and reporting.
///
/// Example:
/// ```dart
/// class MyService with TellingTryCatch {
///   Future<User?> fetchUser(String id) async {
///     return tryRun(
///       context: 'fetch_user',
///       metadata: {'user_id': id},
///       func: () async {
///         final response = await api.getUser(id);
///         return User.fromJson(response);
///       },
///     );
///   }
/// }
/// ```
mixin TellingTryCatch {
  /// Executes an async function and automatically captures any exceptions.
  ///
  /// Returns the result of [func] on success, or `null` on failure.
  ///
  /// [func] - The async function to execute
  /// [context] - A label to identify where this operation runs (e.g., 'checkout_flow')
  /// [metadata] - Additional data to include with any error report
  /// [onSuccess] - Optional callback for successful execution
  /// [onError] - Optional callback for error handling (called after reporting to Telling)
  /// [rethrow] - If true, rethrows the exception after capturing it (default: false)
  Future<T?> tryRun<T>({
    required Future<T> Function() func,
    String? context,
    Map<String, dynamic>? metadata,
    VoidCallback? onSuccess,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool rethrowException = false,
  }) async {
    try {
      final result = await func();
      onSuccess?.call();
      return result;
    } catch (e, stackTrace) {
      // Report to Telling
      Telling.instance.captureException(e, stackTrace, context, metadata);

      // Call custom error handler if provided
      onError?.call(e, stackTrace);

      // Optionally rethrow
      if (rethrowException) {
        rethrow;
      }

      return null;
    }
  }

  /// Executes a void async function and automatically captures any exceptions.
  ///
  /// Similar to [tryRun] but for functions that don't return a value.
  ///
  /// [func] - The async function to execute
  /// [context] - A label to identify where this operation runs
  /// [metadata] - Additional data to include with any error report
  /// [onSuccess] - Optional callback for successful execution
  /// [onError] - Optional callback for error handling
  /// [rethrow] - If true, rethrows the exception after capturing it (default: false)
  Future<void> tryRunVoid({
    required Future<void> Function() func,
    String? context,
    Map<String, dynamic>? metadata,
    VoidCallback? onSuccess,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool rethrowException = false,
  }) async {
    try {
      await func();
      onSuccess?.call();
    } catch (e, stackTrace) {
      // Report to Telling
      Telling.instance.captureException(e, stackTrace, context, metadata);

      // Call custom error handler if provided
      onError?.call(e, stackTrace);

      // Optionally rethrow
      if (rethrowException) {
        rethrow;
      }
    }
  }

  /// Executes a synchronous function and automatically captures any exceptions.
  ///
  /// Returns the result of [func] on success, or `null` on failure.
  ///
  /// [func] - The synchronous function to execute
  /// [context] - A label to identify where this operation runs
  /// [metadata] - Additional data to include with any error report
  /// [onError] - Optional callback for error handling
  /// [rethrow] - If true, rethrows the exception after capturing it (default: false)
  T? tryRunSync<T>({
    required T Function() func,
    String? context,
    Map<String, dynamic>? metadata,
    void Function(Object error, StackTrace stackTrace)? onError,
    bool rethrowException = false,
  }) {
    try {
      return func();
    } catch (e, stackTrace) {
      // Report to Telling
      Telling.instance.captureException(e, stackTrace, context, metadata);

      // Call custom error handler if provided
      onError?.call(e, stackTrace);

      // Optionally rethrow
      if (rethrowException) {
        rethrow;
      }

      return null;
    }
  }
}
