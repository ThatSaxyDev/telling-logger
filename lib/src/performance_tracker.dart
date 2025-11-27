import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Tracks application performance metrics like startup time and frame rate
/// 
/// Note: Currently disabled for MVP. Ready to enable when scaling.
/// Uncomment initialization in telling.dart to activate.
class PerformanceTracker {
  DateTime? _appStartTime;
  final Function(String, Map<String, dynamic>) _onMetric;
  bool _isTracking = false;

  PerformanceTracker(this._onMetric);

  /// Start tracking performance metrics
  void start() {
    if (_isTracking) return;
    _isTracking = true;
    
    _trackAppStartup();
    _trackFrameRate();
    // _trackMemoryUsage(); // Commented out for MVP - overkill
  }

  /// Track app startup time
  void _trackAppStartup() {
    _appStartTime = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isTracking) return;
      final startupTime = DateTime.now().difference(_appStartTime!);
      
      _onMetric('App Startup', {
        'startup_time_ms': startupTime.inMilliseconds,
        'is_cold_start': true,
      });
    });
  }

  /// Track frame rate (FPS)
  void _trackFrameRate() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      if (!_isTracking || timings.isEmpty) return;
      
      final totalFrameTime = timings.fold<Duration>(
        Duration.zero,
        (sum, timing) => sum + timing.totalSpan,
      );
      
      final avgFrameTime = totalFrameTime.inMicroseconds / timings.length;
      if (avgFrameTime == 0) return;
      
      final fps = 1000000 / avgFrameTime; // Convert to FPS
      
      // Only report if we have enough frames for a meaningful average
      if (timings.length >= 10) {
        _onMetric('Frame Rate', {
          'avg_fps': fps.round(),
          'frame_count': timings.length,
          'avg_frame_time_ms': (avgFrameTime / 1000).round(),
        });
      }
    });
  }

  /// Track memory usage (basic)
  // void _trackMemoryUsage() {
  //   // Periodic memory check (every 60 seconds)
  //   Future.delayed(const Duration(seconds: 60), () {
  //     if (!_isTracking) return;
  //     
  //     // Note: Detailed memory tracking requires platform channels
  //     // For now we just send a heartbeat that could be enhanced later
  //     _onMetric('Performance Heartbeat', {
  //       'timestamp': DateTime.now().toIso8601String(),
  //     });
  //     
  //     _trackMemoryUsage(); // Repeat
  //   });
  // }

  /// Stop tracking performance metrics
  void stop() {
    _isTracking = false;
  }
}
