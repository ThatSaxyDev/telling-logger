import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/device_metadata.dart';

class DeviceInfoCollector {
  /// Collects device metadata once during SDK initialization
  /// Note: sessionId is managed separately in the Telling class
  static Future<DeviceMetadata> collect() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String? platform;
      String? osVersion;
      String? deviceModel;
      
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        platform = 'Web';
        osVersion = '${webInfo.browserName} ${webInfo.appVersion}';
        deviceModel = webInfo.platform ?? 'Unknown';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'Android';
        osVersion = 'Android ${androidInfo.version.release}';
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'iOS';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.utsname.machine;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        platform = 'macOS';
        osVersion = macInfo.osRelease;
        deviceModel = macInfo.model;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        platform = 'Windows';
        osVersion = windowsInfo.productName;
        deviceModel = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        platform = 'Linux';
        osVersion = linuxInfo.prettyName;
        deviceModel = linuxInfo.machineId ?? 'Unknown';
      }
      
      return DeviceMetadata(
        platform: platform,
        osVersion: osVersion,
        deviceModel: deviceModel,
        appVersion: packageInfo.version,
        appBuildNumber: packageInfo.buildNumber,
      );
    } catch (e) {
      // Fallback if device info collection fails
      return DeviceMetadata(
        platform: kIsWeb ? 'Web' : 'Unknown',
      );
    }
  }
}
