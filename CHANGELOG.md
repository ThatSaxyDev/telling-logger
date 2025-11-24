# Changelog

All notable changes to this project will be documented in this file.

## 1.0.5 - 2024-11-24

### Changed
- **Internal**: Updated backend API URL to point to the new server instance.

## 1.0.4 - 2024-11-24

### Improved
- **Documentation**: Enhanced README with improved structure and clarity
  - Refined feature descriptions and usage examples
  - Better organization of sections

## 1.0.3 - 2024-11-23

### Improved
- **Documentation**: Added "Get Your API Key" section to README
  - Clear instructions on how to obtain API keys from the dashboard
  - Added direct link to the Telling Dashboard

## 1.0.2 - 2024-11-23

### Improved
- **Streamlined Documentation**: Simplified README for better clarity
  - Removed verbose sections to focus on core features
  - Cleaner, more concise documentation
- **Updated Contact Information**: Updated support email and author details

## 1.0.1 - 2024-11-23

### Changed
- **Production-Safe Logging**: All debug `print` statements now wrapped with `kDebugMode` checks
  - Debug logs are automatically stripped from release builds (tree-shaken)
  - Zero performance overhead in production
- **Simplified API**: Removed configurable rate limiting and baseUrl parameters
  - Rate limiting now uses optimal fixed values (5s deduplication, 5s crash throttle, 10 logs/sec)
  - Backend URL is now fixed internally
  - Cleaner, simpler initialization - just provide your API key

### Improved
- **Documentation**: Comprehensive README with 600+ lines covering all features
  - Added widget tracking extension documentation
  - Included best practices and troubleshooting sections
  - Added performance benchmarks and optimization details

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
