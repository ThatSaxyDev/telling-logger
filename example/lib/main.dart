import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Telling SDK
  // Replace 'YOUR_API_KEY' with a valid key from your dashboard
  await Telling.instance.init('b30-A25bpbnaKm15yjv47z2beTYnYCNeeN12bAIQAUI=');

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Telling Logger!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ).nowTelling(
              name: 'Welcome Text',
              metadata: {'font_size': 20},
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Telling.instance.log('Info button clicked');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged Info')),
                );
              },
              child: const Text('Log Info'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 30),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                // Simulate a crash
                throw StateError('This is a forced crash for testing!');
              },
              child: const Text('Force Crash'),
            ),
          ],
        ),
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
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Home'),
        ),
      ),
    );
  }
}
