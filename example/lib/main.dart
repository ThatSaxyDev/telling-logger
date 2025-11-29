import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Telling SDK
  // Replace 'YOUR_API_KEY' with a valid key from your dashboard
  await Telling.instance.init(
    'API_KEY',
    enableDebugLogs: true,
  );

  // Enable crash reporting
  Telling.instance.enableCrashReporting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telling Logger Example',
      navigatorObservers: [
        // Track screen views automatically
        Telling.instance.screenTracker,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: 'user_123');
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'john@example.com');

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Set user context in Telling SDK
      Telling.instance.setUser(
        userId: _idController.text,
        userName: _nameController.text,
        userEmail: _emailController.text,
      );

      // Set initial user properties
      Telling.instance.setUserProperties({
        'subscription_tier': 'free',
        'signup_date': DateTime.now().toIso8601String(),
        'platform': 'mobile',
      });

      // Navigate to Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: const RouteSettings(name: 'HomeScreen'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter User Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ).nowTelling(name: 'Login Header'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Set User Context & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telling Logger Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Clear user context on logout
              Telling.instance.clearUser();
              Telling.instance.clearUserProperties();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                  settings: const RouteSettings(name: 'LoginScreen'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome to Telling Logger!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).nowTelling(
              name: 'Welcome Text',
              metadata: {'font_size': 20},
            ),
            const SizedBox(height: 30),

            // Logging Section
            const Text(
              'Basic Logging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Telling.instance.log('Info button clicked');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged Info')),
                    );
                  },
                  child: const Text('Log Info'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    Telling.instance.log(
                      'Warning: Battery low',
                      level: LogLevel.warning,
                      metadata: {'battery_level': 15},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged Warning')),
                    );
                  },
                  child: const Text('Log Warning'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    try {
                      throw Exception('Test Exception');
                    } catch (e, stack) {
                      Telling.instance.log(
                        'Error occurred',
                        level: LogLevel.error,
                        error: e,
                        stackTrace: stack,
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged Error')),
                    );
                  },
                  child: const Text('Log Error'),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),

            // User Properties Section
            Row(
              spacing: 10,
              children: [
                const Text(
                  'User Properties',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserPropertiesScreen(),
                        settings:
                            const RouteSettings(name: 'UserPropertiesScreen'),
                      ),
                    );
                  },
                  child: const Text('Panel'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance
                        .setUserProperty('subscription_tier', 'premium');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✅ Set: subscription_tier = premium')),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('Set Premium'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance
                        .setUserProperty('subscription_tier', 'enterprise');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('✅ Set: subscription_tier = enterprise')),
                    );
                  },
                  icon: const Icon(Icons.business, size: 18),
                  label: const Text('Set Enterprise'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance.setUserProperties({
                      'mrr': 299.99,
                      'seats': 10,
                      'industry': 'SaaS',
                      'plan_renewal_date': '2025-12-31',
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              '✅ Set 4 properties (mrr, seats, industry, renewal_date)')),
                    );
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Set Bulk Properties'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final tier =
                        Telling.instance.getUserProperty('subscription_tier');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Current tier: ${tier ?? "not set"}')),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Get Property'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance.clearUserProperties();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('🗑️ Cleared all properties')),
                    );
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),

            // Analytics Events Section
            const Text(
              'Analytics Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance.event(
                      'button_clicked',
                      properties: {
                        'button_name': 'Purchase',
                        'screen': 'Home',
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📊 Event: button_clicked')),
                    );
                  },
                  icon: const Icon(Icons.touch_app, size: 18),
                  label: const Text('Track Button Click'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Telling.instance.event(
                      'purchase_completed',
                      properties: {
                        'amount': 49.99,
                        'currency': 'USD',
                        'product_id': 'premium_monthly',
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('📊 Event: purchase_completed')),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Track Purchase'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                        settings: const RouteSettings(name: 'CheckoutScreen'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Checkout'),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),

            // Navigation Section
            const Text(
              'Navigation & Testing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserPropertiesScreen(),
                        settings:
                            const RouteSettings(name: 'UserPropertiesScreen'),
                      ),
                    );
                  },
                  child: const Text('📋 User Properties Panel'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SecondScreen(),
                        settings: const RouteSettings(name: 'SecondScreen'),
                      ),
                    );
                  },
                  child: const Text('Go to Second Screen'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    // Simulate a crash
                    throw StateError('This is a forced crash for testing!');
                  },
                  child: const Text('💥 Force Crash'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserPropertiesScreen extends StatefulWidget {
  const UserPropertiesScreen({super.key});

  @override
  State<UserPropertiesScreen> createState() => _UserPropertiesScreenState();
}

class _UserPropertiesScreenState extends State<UserPropertiesScreen> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  final Map<String, dynamic> _currentProperties = {};

  @override
  void initState() {
    super.initState();
    // Initialize with some common properties
    _currentProperties['subscription_tier'] =
        Telling.instance.getUserProperty('subscription_tier') ?? 'free';
  }

  void _setCustomProperty() {
    if (_keyController.text.isEmpty || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both key and value')),
      );
      return;
    }

    // Try to parse as number, otherwise use as string
    dynamic value = _valueController.text;
    if (double.tryParse(_valueController.text) != null) {
      value = double.parse(_valueController.text);
    }

    Telling.instance.setUserProperty(_keyController.text, value);

    setState(() {
      _currentProperties[_keyController.text] = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Set: ${_keyController.text} = $value')),
    );

    _keyController.clear();
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Properties Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set Custom Property',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. age',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 25',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _setCustomProperty,
                  child: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickPropertyButton(
                  label: 'Set Age: 25',
                  onPressed: () {
                    Telling.instance.setUserProperty('age', 25);
                    setState(() => _currentProperties['age'] = 25);
                  },
                ),
                _QuickPropertyButton(
                  label: 'Set Country: US',
                  onPressed: () {
                    Telling.instance.setUserProperty('country', 'US');
                    setState(() => _currentProperties['country'] = 'US');
                  },
                ),
                _QuickPropertyButton(
                  label: 'Set Premium',
                  onPressed: () {
                    Telling.instance
                        .setUserProperty('subscription_tier', 'premium');
                    setState(() =>
                        _currentProperties['subscription_tier'] = 'premium');
                  },
                ),
                _QuickPropertyButton(
                  label: 'Set MRR: 99.99',
                  onPressed: () {
                    Telling.instance.setUserProperty('mrr', 99.99);
                    setState(() => _currentProperties['mrr'] = 99.99);
                  },
                ),
                _QuickPropertyButton(
                  label: 'Clear All',
                  color: Colors.red,
                  onPressed: () {
                    Telling.instance.clearUserProperties();
                    setState(() => _currentProperties.clear());
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Current Properties (Local View)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _currentProperties.isEmpty
                  ? const Center(
                      child: Text(
                        'No properties set yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _currentProperties.length,
                      itemBuilder: (context, index) {
                        final key = _currentProperties.keys.elementAt(index);
                        final value = _currentProperties[key];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.label),
                            title: Text(key),
                            subtitle: Text(
                              value.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Telling.instance.clearUserProperty(key);
                                setState(() => _currentProperties.remove(key));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cleared: $key')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '💡 Tip: Properties are automatically included in all log events for segmentation',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPropertyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _QuickPropertyButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: color != null
          ? ElevatedButton.styleFrom(backgroundColor: color)
          : null,
      child: Text(label),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _shippingController = TextEditingController();
  final _cardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Track Step 1: Cart Viewed
    Telling.instance.trackFunnel(
      'checkout_flow',
      'cart_viewed',
      step: 1,
      properties: {'item_count': 2, 'total_value': 49.99},
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Moving to Shipping
      setState(() => _currentStep = 1);
      Telling.instance.trackFunnel(
        'checkout_flow',
        'shipping_started',
        step: 2,
      );
    } else if (_currentStep == 1) {
      // Moving to Payment
      if (_shippingController.text.isNotEmpty) {
        setState(() => _currentStep = 2);
        Telling.instance.trackFunnel(
          'checkout_flow',
          'shipping_completed',
          step: 3,
          properties: {'address_length': _shippingController.text.length},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter shipping info')),
        );
      }
    } else if (_currentStep == 2) {
      // Completing Order
      if (_cardController.text.isNotEmpty) {
        Telling.instance.trackFunnel(
          'checkout_flow',
          'payment_completed',
          step: 4,
          properties: {'payment_method': 'credit_card'},
        );

        // Track the final conversion event too
        Telling.instance.event('purchase_completed', properties: {
          'amount': 49.99,
          'currency': 'USD',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Order Placed! Funnel Complete.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter card info')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Flow')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.of(context).pop();
          }
        },
        steps: [
          Step(
            title: const Text('Review Cart'),
            content: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Premium Plan'),
                  subtitle: Text('\$49.99 / month'),
                ),
                ListTile(
                  leading: Icon(Icons.confirmation_number),
                  title: Text('Setup Fee'),
                  subtitle: Text('\$0.00'),
                ),
                Divider(),
                Text('Total: \$49.99',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Shipping Info'),
            content: TextField(
              controller: _shippingController,
              decoration: const InputDecoration(
                labelText: 'Shipping Address',
                border: OutlineInputBorder(),
              ),
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Payment'),
            content: TextField(
              controller: _cardController,
              decoration: const InputDecoration(
                labelText: 'Card Number (Fake)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            isActive: _currentStep >= 2,
            state: StepState.editing,
          ),
        ],
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This screen demonstrates automatic screen tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
