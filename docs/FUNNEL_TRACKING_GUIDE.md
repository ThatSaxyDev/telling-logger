# Funnel Tracking Guide for Telling Logger

This guide outlines the best practices for implementing funnel tracking in your Flutter application using the `telling_logger` package.

## What is Funnel Tracking?

Funnel tracking allows you to monitor a user's journey through a specific series of steps towards a goal (conversion). By tracking each step, you can identify where users drop off and optimize your application's flow.

Common examples include:
- **Onboarding**: Splash Screen -> Sign Up -> Profile Setup -> Home Screen
- **E-commerce**: View Product -> Add to Cart -> Checkout -> Payment -> Purchase
- **Feature Adoption**: Open Feature -> Interact with Tool -> Save Result

## Basic Implementation

The `telling_logger` SDK provides a dedicated method `trackFunnel` to simplify this process.

### Method Signature

```dart
void trackFunnel({
  required String funnelName,
  required String stepName,
  int? step,
  Map<String, dynamic>? properties,
});
```

- **`funnelName`**: A unique identifier for the entire flow (e.g., `'onboarding_flow'`, `'checkout_process'`). This **must** be consistent across all steps in the funnel.
- **`stepName`**: A descriptive name for the specific step (e.g., `'email_entered'`, `'payment_successful'`).
- **`step`**: (Optional but Recommended) An integer representing the order of the step (1, 2, 3...).
- **`properties`**: (Optional) Additional metadata relevant to that specific step.

---

## Best Practices

### 1. Consistent Naming
Choose a clear, snake_case name for your `funnelName` and stick to it. If you change the name halfway through a flow, it will be treated as a different funnel.

**Good:** `'user_onboarding'`
**Bad:** `'User Onboarding'`, `'onboarding_v2'` (unless intentionally versioning)

### 2. Sequential Step Numbers
Always provide the `step` parameter. While the backend might infer order based on timestamps, providing explicit step numbers (1, 2, 3) makes analysis significantly easier and more robust against async timing issues.

### 3. Granular Step Names
Make your `stepName` descriptive of the *action completed* or the *state reached*.

- **Good:** `'cart_viewed'`, `'shipping_info_submitted'`, `'payment_processed'`
- **Bad:** `'step1'`, `'next'`, `'done'`

### 4. Enrich with Properties
Use the `properties` map to add context that might explain drop-offs.

*   **Example:** When tracking a "Sign Up" step, you might add `{'method': 'email'}` or `{'method': 'google'}`.
*   **Example:** When tracking a "Checkout" step, add `{'cart_value': 99.99, 'item_count': 3}`.

### 5. Track the "Start" and "End"
Ensure you track the very first interaction as Step 1. This gives you the baseline to calculate conversion rates. Similarly, track the final success state as the last step.

---

## Example Scenarios

### Scenario A: User Onboarding

```dart
// Step 1: User lands on the welcome screen
Telling.instance.trackFunnel(
  funnelName: 'user_onboarding',
  stepName: 'welcome_screen_viewed',
  step: 1,
);

// Step 2: User clicks "Get Started"
Telling.instance.trackFunnel(
  funnelName: 'user_onboarding',
  stepName: 'get_started_clicked',
  step: 2,
);

// Step 3: User submits registration form
Telling.instance.trackFunnel(
  funnelName: 'user_onboarding',
  stepName: 'registration_submitted',
  step: 3,
  properties: {'method': 'email'},
);

// Step 4: User completes profile setup (Conversion)
Telling.instance.trackFunnel(
  funnelName: 'user_onboarding',
  stepName: 'profile_completed',
  step: 4,
);
```

### Scenario B: E-Commerce Checkout (from Example App)

This example mirrors the implementation in `example/lib/main.dart`.

```dart
final String checkoutFunnel = 'checkout_flow';

// Step 1: User views their cart
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'cart_viewed',
  step: 1,
  properties: {'item_count': 2, 'total_value': 49.99},
);

// Step 2: User starts shipping entry
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'shipping_started',
  step: 2,
);

// Step 3: User completes shipping info
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'shipping_completed',
  step: 3,
  properties: {'address_length': 45},
);

// Step 4: Payment successful (Conversion)
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'payment_completed',
  step: 4,
  properties: {'payment_method': 'credit_card'},
);
```

## Troubleshooting

- **Missing Steps**: Ensure `trackFunnel` is called *after* the action is confirmed (e.g., inside the `onPressed` callback or after form validation).
- **Mixed Funnels**: Double-check that `funnelName` is identical across all steps. A typo like `'checkout'` vs `'checkout_flow'` will break the analysis.
- **Rate Limiting**: The SDK has a rate limiter. If you track steps in extremely rapid succession (milliseconds apart), some might be dropped. For normal user flows, this is rarely an issue.
