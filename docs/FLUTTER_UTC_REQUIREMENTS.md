# UTC Timestamp Requirements for Flutter App

## Problem Statement

The backend analytics system was experiencing timezone inconsistencies when comparing timestamps. Events logged from the Flutter app were being filtered incorrectly due to timezone mismatches between the client and server.

## Root Cause

The issue occurred because:
1. Flutter app was using `DateTime.now()` which captures timestamps in **local timezone**
2. Backend was also using `DateTime.now()` which captures server's **local timezone** (potentially different from client)
3. When comparing timestamps in date range queries, the mismatched timezones caused incorrect filtering

For example:
- Client in timezone UTC+1 logs event at 05:00 local time → stored as "2025-01-29T05:00:00+01:00"
- Backend in UTC timezone creates date range ending at 04:30 UTC
- Event appears to be "in the future" from backend's perspective and gets filtered out

## Backend Fix (Completed)

The backend has been updated to use **UTC consistently** for all timestamp operations:
- Changed `DateTime.now()` to `DateTime.now().toUtc()` in all analytics handlers
- Changed `DateTime.parse(dateString)` to `DateTime.parse(dateString).toUtc()`
- Changed `DateTime(year, month, day)` to `DateTime.utc(year, month, day)`

## Required Flutter Frontend Changes

> [!IMPORTANT]
> The Flutter app MUST save all timestamps in UTC to ensure consistency with the backend.

### Current Implementation (Problematic)
```dart
// ❌ WRONG - Uses local timezone
final timestamp = DateTime.now();
```

### Required Implementation
```dart
// ✅ CORRECT - Uses UTC
final timestamp = DateTime.now().toUtc();
```

## Files to Update in Flutter App

Search for all occurrences of `DateTime.now()` in the Flutter codebase where timestamps are being saved to the backend, and update them to `DateTime.now().toUtc()`.

Specific areas to check:
1. **Log creation** - When creating log entries to send to the backend
2. **Event tracking** - When tracking analytics events
3. **Funnel tracking** - When tracking funnel steps with timestamps
4. **Performance metric tracking** - When recording performance data
5. **User property updates** - When updating user properties with timestamps

### Example Fix Pattern

**Before:**
```dart
final log = {
  'timestamp': DateTime.now().toIso8601String(),
  'message': 'User logged in',
  // ... other fields
};
```

**After:**
```dart
final log = {
  'timestamp': DateTime.now().toUtc().toIso8601String(),
  'message': 'User logged in',
  // ... other fields
};
```

## Verification

After making changes:
1. Test funnel analysis with events tracked just a few minutes ago
2. Verify analytics timeline shows events immediately
3. Check that date range filters work correctly regardless of client timezone

## Database Storage

> [!NOTE]
> PostgreSQL stores timestamps in UTC by default when using the `timestamp` or `timestamptz` types. The issue was not with storage, but with the comparison logic using mismatched timezone-aware DateTime objects.

## Additional Recommendations

1. **Test in different timezones** - Ensure the app works correctly for users in different timezones
2. **Display timestamps** - When displaying timestamps to users in the UI, convert UTC back to local time for better UX:
   ```dart
   final utcTime = DateTime.parse(timestamp); // This is in UTC from backend
   final localTime = utcTime.toLocal(); // Convert to local for display
   ```
3. **Date pickers** - When users select dates for filtering, ensure the selected dates are converted to UTC before sending to the backend

## Impact

This fix ensures:
- ✅ Funnel analysis returns correct counts immediately after events are logged
- ✅ Analytics timeline shows events in the correct time buckets
- ✅ Date range filters work consistently across all timezones
- ✅ No more "delayed" analytics due to timezone offsets
