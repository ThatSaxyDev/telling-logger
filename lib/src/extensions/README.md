# Widget Tracking Extension

The `.nowTelling()` extension provides automatic view tracking for any Flutter widget.

## Usage

Wrap any widget with `.nowTelling()` to automatically log when it appears on screen:

```dart
import 'package:telling_logger/telling_logger.dart';

// Basic usage
MyWidget().nowTelling()

// With custom name
MyWidget().nowTelling(name: 'Dashboard Screen')

// With metadata
MyWidget().nowTelling(
  name: 'Product Detail',
  metadata: {'productId': '123', 'category': 'electronics'},
)

// Custom log type and level
MyWidget().nowTelling(
  name: 'Checkout Flow',
  type: LogType.analytics,
  level: LogLevel.info,
)

// Track every time (default tracks only once)
MyWidget().nowTelling(
  name: 'Banner Ad',
  trackOnce: false,
)
```

## Parameters

-  **`name`** (`String?`): Name of the view/widget
   - Default: Uses widget's `runtimeType`
   
- **`type`** (`LogType?`): Type of log event
   - Default: `LogType.analytics`
   - Options: `general`, `analytics`, `event`, `performance`, `network`, `security`, `exception`, `crash`, `custom`

- **`level`** (`LogLevel?`): Log level
   - Default: `LogLevel.info`
   - Options: `trace`, `debug`, `info`, `warning`, `error`, `fatal`

- **`metadata`** (`Map<String, dynamic>?`): Additional data to track
   - Default: `null`

- **`trackOnce`** (`bool`): Only track the first appearance
   - Default: `true`
   - Set to `false` to track every time the widget appears

## How It Works

The extension wraps your widget with an internal `_TellingWrapper` that:

1. **Tracks on mount**: Logs when the widget enters the widget tree (`initState`)
2. **Automatic metadata**: Adds `view_name` and `timestamp` to your metadata
3. **Smart tracking**: Respects `trackOnce` to avoid duplicate logs
4. **Non-intrusive**: Returns your widget unchanged, just wrapped

## Examples

### Screen View Tracking

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Welcome!'),
      ),
    ).nowTelling(name: 'Home Screen');
  }
}
```

### Component Visibility Tracking

```dart
if (isPremiumUser) {
  PremiumFeatureWidget().nowTelling(
    name: 'Premium Feature Shown',
    metadata: {'userId': userId},
  )
}
```

### Ad Impression Tracking

```dart
AdBanner(
  adId: 'banner_123',
).nowTelling(
  name: 'Ad Impression',
  trackOnce: false, // Track every rebuild
  metadata: {'adId': 'banner_123', 'placement': 'home_top'},
)
```

## Best Practices

1. **Use descriptive names**: `'Checkout Screen'` is better than `'Screen3'`
2. **Add context in metadata**: Include IDs, categories, user segments, etc.
3. **Track significant views**: Don't track every tiny widget, focus on screens and important components
4. **Use `trackOnce: true`** for screens (default)
5. **Use `trackOnce: false`** for components that should track every appearance

## Notes

- Requires `Telling.instance.init()` to be called first
- Works with both `StatelessWidget` and ` StatefulWidget`
- Minimal performance impact - uses `addPostFrameCallback`
- Automatically includes session data if session tracking is enabled
