class DeviceMetadata {
  final String? platform; // iOS, Android, Web, etc.
  final String? osVersion;
  final String? deviceModel;
  final String? appVersion;
  final String? appBuildNumber;
  final String sessionId;

  DeviceMetadata({
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.appVersion,
    this.appBuildNumber,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (appVersion != null) 'appVersion': appVersion,
      if (appBuildNumber != null) 'appBuildNumber': appBuildNumber,
      'sessionId': sessionId,
    };
  }
}
