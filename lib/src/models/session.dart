/// Represents a user session within the application
class Session {
  /// Unique identifier for this session
  final String sessionId;
  
  /// When the session started
  final DateTime startTime;
  
  /// When the session ended (null if ongoing)
  DateTime? endTime;
  
  /// User ID associated with this session
  final String? userId;
  
  /// User email associated with this session
  final String? userEmail;
  
  /// User name associated with this session
  final String? userName;

  Session({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.userId,
    this.userEmail,
    this.userName,
  });

  /// Calculate session duration
  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    // If session is ongoing, calculate duration from start to now
    return DateTime.now().difference(startTime);
  }
  
  /// Check if session is currently active
  bool get isActive => endTime == null;

  /// Convert session to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'durationSeconds': duration?.inSeconds,
      'isActive': isActive,
    };
  }
}
