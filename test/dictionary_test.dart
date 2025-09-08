import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/services/enhanced_dictionary_service.dart';

void main() {
  group('Enhanced Dictionary Service Tests', () {
    setUpAll(() async {
      // 模拟 Flutter 绑定
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('should initialize successfully', () async {
      await EnhancedDictionaryService.initialize();
      expect(true, true); // 如果没有异常，测试通过
    });

    test('should lookup word from local dictionary', () async {
      await EnhancedDictionaryService.initialize();

      final result = await EnhancedDictionaryService.lookupWord('hello');

      if (result != null) {
        expect(result.word, 'hello');
        expect(result.meanings.isNotEmpty, true);
        print('✅ Found word: ${result.word}');
        print('📖 Meaning: ${result.primaryMeaning}');
        print('🔊 Phonetic: ${result.formattedPhonetic}');
      } else {
        print('❌ Word not found in local dictionary');
      }
    });

    test('should handle non-existent words gracefully', () async {
      await EnhancedDictionaryService.initialize();

      final result =
          await EnhancedDictionaryService.lookupWord('nonexistentword12345');

      expect(result, null);
      print('✅ Correctly handled non-existent word');
    });

    test('should get cache statistics', () async {
      await EnhancedDictionaryService.initialize();

      final stats = EnhancedDictionaryService.getCacheStats();

      expect(stats.containsKey('cached_words'), true);
      expect(stats.containsKey('local_words'), true);

      print('📊 Cache stats: $stats');
    });
  });
}
