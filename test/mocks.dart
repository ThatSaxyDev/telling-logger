import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mocks for these classes
// Run: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([http.Client])
void main() {}
