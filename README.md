# telling_logger

[![pub package](https://img.shields.io/pub/v/telling_logger.svg)](https://pub.dev/packages/telling_logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A comprehensive crash reporting, error tracking, and analytics SDK for Flutter applications. Track errors, monitor performance, and gain insights into your app's behavior with minimal setup.

## Features

- 🐛 **Automatic Crash Reporting** - Catches unhandled Flutter and platform errors
- 📊 **Event Analytics** - Track user actions and custom events
- 📱 **Device Metadata** - Auto-collects platform, OS, device model, and app info
- 🔄 **Session Tracking** - Automatic session management with lifecycle hooks
- 📍 **Screen Tracking** - Built-in NavigatorObserver for automatic screen view tracking
- 👤 **User Context** - Associate logs with specific users
- ⚡ **Smart Batching** - Efficient log batching to minimize network requests
- 🔌 **Offline Support** - Buffers logs when offline, sends when connected
- 🛡️ **Rate Limiting** - Built-in deduplication and throttling to prevent spam
- 🌍 **Cross-platform** - Works on iOS, Android, Web, macOS, Windows, and Linux

## Installation

Add `telling_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  telling_logger: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the SDK

In your `main.dart`, initialize the SDK before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Telling
  await Telling.instance.init(
    'YOUR_API_KEY',
    baseUrl: 'https://your-backend.com/api/v1/logs',
  );
  
  // Enable automatic crash reporting
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

### 2. Log Events

```dart
// Simple log
Telling.instance.log('User completed onboarding');

// Log with level and metadata
Telling.instance.log(
  'Payment processed',
  level: LogLevel.info,
  metadata: {
    'amount': 29.99,
    'currency': 'USD',
    'payment_method': 'card',
  },
);

// Log errors
try {
  riskyOperation();
} catch (e, stack) {
  Telling.instance.log(
    'Operation failed',
    level: LogLevel.error,
    error: e,
    stackTrace: stack,
  );
}
```

### 3. Track Analytics

```dart
// Track custom events
Telling.instance.event(
  'button_clicked',
  properties: {
    'button_name': 'Sign Up',
    'screen': 'Landing Page',
  },
);
```

## Advanced Usage

### User Context

Set user information to associate logs with specific users:

```dart
// After user login
Telling.instance.setUser(
  userId: 'user_123',
  userName: 'John Doe',
  userEmail: 'john@example.com',
);

// After logout
Telling.instance.clearUser();
```

### Screen Tracking

Automatically track screen views using the built-in NavigatorObserver:

#### With MaterialApp

```dart
MaterialApp(
  navigatorObservers: [
    Telling.instance.screenTracker,
  ],
  // ...
);
```

#### With go_router

```dart
final router = GoRouter(
  observers: [
    Telling.instance.goRouterScreenTracker,
  ],
  // ...
);
```

### Rate Limiting Configuration

Customize rate limiting to control log volume:

```dart
await Telling.instance.init(
  'YOUR_API_KEY',
  baseUrl: 'https://your-backend.com/api/v1/logs',
  deduplicationWindow: Duration(seconds: 30),
  crashThrottleWindow: Duration(minutes: 5),
  maxLogsPerSecond: 10,
);
```

### Log Levels

- `LogLevel.debug` - Detailed information for debugging
- `LogLevel.info` - General informational messages
- `LogLevel.warning` - Warning messages for potentially harmful situations
- `LogLevel.error` - Error events that might still allow the app to continue
- `LogLevel.fatal` - Severe errors causing app termination

### Log Types

- `LogType.general` - Standard application logs
- `LogType.analytics` - Analytics and event tracking
- `LogType.crash` - Application crashes and fatal errors
- `LogType.network` - Network-related logs
- `LogType.performance` - Performance monitoring

## Example App

Check out the [example](https://github.com/ThatSaxyDev/telling-logger/tree/main/example) directory for a complete sample app.

## Backend Integration

This SDK is designed to work with the Telling backend. You can:
- Use the open-source Telling backend ([GitHub](https://github.com/ThatSaxyDev/telling))
- Build your own backend that accepts the SDK's JSON payload format

### Expected Payload Format

```json
[
  {
    "type": "analytics",
    "level": "info",
    "message": "User logged in",
    "timestamp": "2024-11-23T10:30:00.000Z",
    "metadata": { "screen": "Login" },
    "device": { "platform": "iOS", "osVersion": "17.0" },
    "userId": "user_123",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "sessionId": "session_abc123"
  }
]
```

## Platform Support

| Platform | Supported |
|----------|-----------|
| iOS      | ✅ |
| Android  | ✅ |
| Web      | ✅ |
| macOS    | ✅ |
| Windows  | ✅ |
| Linux    | ✅ |

## Performance

- **Minimal overhead**: Logs are batched and sent asynchronously
- **Efficient deduplication**: Prevents duplicate logs from flooding your backend
- **Smart rate limiting**: Automatically throttles excessive logging
- **Memory efficient**: Bounded buffer size with automatic cleanup

## Contributing

Contributions are welcome! Please read our [contributing guidelines](https://github.com/ThatSaxyDev/telling-logger/blob/main/CONTRIBUTING.md) before submitting PRs.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@telling.dev
- 🐛 Issues: [GitHub Issues](https://github.com/ThatSaxyDev/telling-logger/issues)
- 📖 Documentation: [Wiki](https://github.com/ThatSaxyDev/telling-logger/wiki)

---

Made with ❤️ by the Telling team
