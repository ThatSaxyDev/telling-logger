import 'package:flutter_test/flutter_test.dart';

import 'package:telling_logger/telling_logger.dart';

void main() {
  test('Telling initialization and logging', () {
    final telling = Telling.instance;
    
    // Test initialization
    telling.init('TEST_API_KEY');
    
    // Test logging (should not throw)
    expect(
      () => telling.log('Test message'),
      returnsNormally,
    );
    
    expect(
      () => telling.log(
        'Test error',
        level: LogLevel.error,
        error: Exception('Test exception'),
      ),
      returnsNormally,
    );
  });
}
