# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 - 2024-11-23

### Initial Release

#### Features
- **Automatic Crash Reporting**: Catch and report unhandled Flutter errors and platform errors
- **Manual Logging**: Support for multiple log levels (debug, info, warning, error, fatal)
- **Event Tracking**: Track analytics events with custom properties
- **Session Management**: Automatic session tracking with start/end events
- **Screen Tracking**: Built-in NavigatorObserver for automatic screen view tracking
- **User Context**: Set and track user information across logs
- **Device Metadata**: Automatic collection of platform, OS, device, and app information
- **Rate Limiting**: Smart deduplication and throttling to prevent log spam
- **Offline Support**: Buffer logs when offline and send when connection is restored
- **Batch Sending**: Efficient batching of logs to reduce network requests

#### Supported Platforms
- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

#### Log Types
- General logs
- Analytics events
- Crashes
- Network tracking
- Performance monitoring

#### Configuration
- Customizable rate limiting
- Adjustable deduplication window
- Configurable crash throttling
- Custom base URL support
