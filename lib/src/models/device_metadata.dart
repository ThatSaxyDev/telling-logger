/// Device metadata collected once per session
/// Note: sessionId is intentionally NOT included here as it's already
/// present at the LogEvent level to avoid data duplication
class DeviceMetadata {
  final String? platform; // iOS, Android, Web, etc.
  final String? osVersion;
  final String? deviceModel;
  final String? appVersion;
  final String? appBuildNumber;

  DeviceMetadata({
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.appVersion,
    this.appBuildNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (appVersion != null) 'appVersion': appVersion,
      if (appBuildNumber != null) 'appBuildNumber': appBuildNumber,
    };
  }

  /// Deserialize from JSON (for loading persisted logs)
  factory DeviceMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceMetadata(
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceModel: json['deviceModel'] as String?,
      appVersion: json['appVersion'] as String?,
      appBuildNumber: json['appBuildNumber'] as String?,
    );
  }
}

