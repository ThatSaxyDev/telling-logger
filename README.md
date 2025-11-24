# Telling Logger 📊

[![pub package](https://img.shields.io/pub/v/telling_logger.svg)](https://pub.dev/packages/telling_logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D1.17.0-blue.svg)](https://flutter.dev)

A **production-ready** crash reporting, error tracking, and analytics SDK for Flutter applications. Monitor your app's health, track user behavior, and gain actionable insights with minimal setup.

## ✨ Features

### Core Capabilities

- 🐛 **Automatic Crash Reporting** – Captures unhandled Flutter framework and platform errors
- 📊 **Event Analytics** – Track custom events, user actions, and business metrics
- 📱 **Rich Device Context** – Auto-collects platform, OS version, device model, and app info
- 🔄 **Session Management** – Automatic session tracking with app lifecycle hooks
- 📍 **Screen Tracking** – Built-in NavigatorObserver for automatic screen view analytics
- 👤 **User Context** – Associate logs with user IDs, names, and emails
- 🎯 **Widget-Level Tracking** – `.nowTelling()` extension for effortless view tracking
- ⚡ **Smart Batching** – Efficient log deduplication and batching to minimize network overhead
- � **Offline Support** – Persists logs when offline, auto-sends when connection is restored
- 🛡️ **Rate Limiting** – Built-in deduplication, throttling, and flood protection
- 🌍 **Cross-Platform** – Works on iOS, Android, Web, macOS, Windows, and Linux

### Developer Experience

- 🚀 **5-Minute Setup** – Initialize with a single line of code
- 📝 **Production-Safe Logging** – Debug logs automatically stripped from release builds
- 🎨 **Flexible API** – Multiple log levels, types, and metadata support

## 📦 Installation

Add `telling_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  telling_logger: ^1.0.4
```

Then install:

```bash
flutter pub get
```

## 🔑 Get Your API Key

To use Telling Logger, you need an API key.

1. Go to the [Telling Dashboard](https://usetelling.netlify.app/).
2. Log in or create an account.
3. Create a new project to obtain your API key.

## 🚀 Quick Start

### 1. Initialize the SDK

In your `main.dart`, initialize Telling before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Telling SDK
  await Telling.instance.init(
    'YOUR_API_KEY',
  );
  
  // Enable automatic crash reporting
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

### 2. Log Events

```dart
// Simple info log
Telling.instance.log('User completed onboarding');

// Log with metadata
Telling.instance.log(
  'Payment processed',
  level: LogLevel.info,
  metadata: {
    'amount': 29.99,
    'currency': 'USD',
    'payment_method': 'stripe',
  },
);

// Error logging
try {
  await processPayment();
} catch (e, stack) {
  Telling.instance.log(
    'Payment failed',
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
    'user_segment': 'free_trial',
  },
);
```

## 📚 Core Concepts

### Log Levels

Control the severity and visibility of your logs:

| Level | Use Case | Severity |
|-------|----------|----------|
| `LogLevel.trace` | Extremely detailed debugging | 0 |
| `LogLevel.debug` | Detailed diagnostic information | 1 |
| `LogLevel.info` | General informational messages | 2 |
| `LogLevel.warning` | Potentially harmful situations | 3 |
| `LogLevel.error` | Runtime errors that allow continuation | 4 |
| `LogLevel.fatal` | Critical errors causing termination | 5 |

### Log Types

Categorize logs for better filtering and analytics:

| Type | Purpose |
|------|---------|
| `LogType.general` | Standard application logs |
| `LogType.analytics` | User behavior and event tracking |
| `LogType.event` | Custom business events |
| `LogType.performance` | Performance metrics and benchmarks |
| `LogType.network` | API calls and network activity |
| `LogType.security` | Security-related events |
| `LogType.exception` | Handled exceptions |
| `LogType.crash` | Application crashes and fatal errors |
| `LogType.custom` | Custom log categories |

## 🎯 Advanced Features

### User Context Tracking

Associate logs with specific users for better debugging and analytics:

```dart
// Set user context after login
Telling.instance.setUser(
  userId: 'user_12345',
  userName: 'Jane Doe',
  userEmail: 'jane@example.com',
);

// Clear user context after logout
Telling.instance.clearUser();
```

All subsequent logs will automatically include user information until cleared.

### Automatic Screen Tracking

#### With MaterialApp

```dart
MaterialApp(
  navigatorObservers: [
    Telling.instance.screenTracker,
  ],
  home: HomeScreen(),
)
```

#### With go_router

```dart
final router = GoRouter(
  observers: [
    Telling.instance.goRouterScreenTracker,
  ],
  routes: [...],
);

MaterialApp.router(
  routerConfig: router,
)
```

Screen views are automatically logged with:
- Screen name
- Previous screen
- Time spent on previous screen
- Session context

### Widget-Level Tracking

Use the `.nowTelling()` extension to track any widget's visibility:

```dart
import 'package:telling_logger/telling_logger.dart';

// Basic usage - tracks when widget appears
Column(
  children: [
    Text('Welcome!'),
  ],
).nowTelling()

// With custom name
ProductCard(product: item).nowTelling(
  name: 'Product Card Impression',
)

// With metadata for context
PremiumFeature().nowTelling(
  name: 'Premium Feature Shown',
  metadata: {
    'feature_id': 'dark_mode',
    'user_tier': 'free',
  },
)

// Track every appearance (not just once)
AdBanner().nowTelling(
  name: 'Banner Ad Impression',
  trackOnce: false,
  metadata: {'ad_id': 'banner_123'},
)

// Custom log type and level
CriticalAlert().nowTelling(
  name: 'Security Alert Displayed',
  type: LogType.security,
  level: LogLevel.warning,
)
```

**Parameters:**
- `name` – Custom name (defaults to widget's runtimeType)
- `type` – Log type (defaults to `LogType.analytics`)
- `level` – Log level (defaults to `LogLevel.info`)
- `metadata` – Additional context data
- `trackOnce` – Track only first appearance (defaults to `true`)


### Session Management

Sessions are automatically managed based on app lifecycle:

- **Session Start**: When app launches or returns from background
- **Session End**: When app goes to background or terminates
- **Session Data**: Duration, user context, device info

```dart
// Session data is automatically included in all logs
{
  "sessionId": "user_123_1700745600000",
  "userId": "user_123",
  "userName": "Jane Doe",
  "userEmail": "jane@example.com"
}
```

### Crash Reporting

Enable automatic crash capture for both Flutter and platform errors:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Telling.instance.init('YOUR_API_KEY');
  
  // Captures:
  // - Flutter framework errors (FlutterError.onError)
  // - Platform dispatcher errors (PlatformDispatcher.onError)
  // - Render issues (marked as warnings)
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

**Crash Intelligence:**
- Render/layout issues are logged as `warnings`
- Actual crashes are logged as `fatal` errors
- Full stack traces included
- Automatic retry with exponential backoff

## 🔧 Configuration Options

### Initialization Parameters

```dart
await Telling.instance.init(
  String apiKey,                      // Required: Your API key
  {
    String? userId,                   // Initial user ID
    String? userName,                 // Initial user name
    String? userEmail,                // Initial user email
  }
);
```

### Environment-Specific Setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const isProduction = bool.fromEnvironment('dart.vm.product');
  
  await Telling.instance.init(
    isProduction ? 'PROD_API_KEY' : 'DEV_API_KEY',
  );
  
  runApp(MyApp());
}
```

## 🎓 Best Practices

### 1. Initialize Early

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize BEFORE runApp
  await Telling.instance.init('API_KEY');
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

### 2. Use Appropriate Log Levels

```dart
// ✅ Good
Telling.instance.log('User login successful', level: LogLevel.info);
Telling.instance.log('Database query slow', level: LogLevel.warning);
Telling.instance.log('Payment failed', level: LogLevel.error);

// ❌ Avoid
Telling.instance.log('Button clicked', level: LogLevel.fatal); // Wrong severity
```

### 3. Add Context with Metadata

```dart
// ✅ Good - rich context
Telling.instance.event('purchase_completed', properties: {
  'product_id': 'premium_monthly',
  'price': 9.99,
  'currency': 'USD',
  'payment_method': 'stripe',
  'user_segment': 'trial_converted',
});

// ❌ Poor - no context
Telling.instance.event('purchase');
```

### 4. Track User Context

```dart
// Set user context after authentication
await signIn(email, password);
Telling.instance.setUser(
  userId: user.id,
  userName: user.name,
  userEmail: user.email,
);

// Clear on logout
await signOut();
Telling.instance.clearUser();
```

### 5. Use Widget Tracking Wisely

```dart
// ✅ Good - track important screens/components
HomeScreen().nowTelling(name: 'Home Screen');
PremiumPaywall().nowTelling(name: 'Paywall Viewed');

// ❌ Avoid - don't track every tiny widget
Text('Hello').nowTelling(); // Too granular
Container().nowTelling();   // Not meaningful
```

### 6. Handle Sensitive Data

```dart
// ❌ Don't log PII or sensitive data
Telling.instance.event('login', properties: {
  'password': '123456', // NEVER
  'credit_card': '4111...', // NEVER
});

// ✅ Hash or omit sensitive fields
Telling.instance.event('login', properties: {
  'email_hash': hashEmail(user.email),
  'login_method': 'email',
});
```


### Common Errors

**"Telling SDK not initialized"**
- Call `await Telling.instance.init()` before using the SDK

**"Invalid API Key" (403)**
- Verify your API key is correct
- Check backend is running and accessible

**"Logs being dropped"**
- Reduce log volume or increase limits


## 📄 License

MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

- � [Documentation](https://github.com/ThatSaxyDev/telling-logger)
- 🐛 [Report Issues](https://github.com/ThatSaxyDev/telling-logger/issues)
- � [Discussions](https://github.com/ThatSaxyDev/telling-logger/discussions)
- 📧 Email: kiishidart@gmail.com

## 🌟 Show Your Support

If Telling Logger helped you build better apps, please:
- ⭐ Star this repo
- 🐦 Share on Twitter
- 📝 Write a blog post
- 💬 Tell your friends

---

**Made with 💙 by Kiishi**

[Website](https://telling.dev) • [Twitter](https://twitter.com/kiishigod) • [GitHub](https://github.com/ThatSaxyDev)
