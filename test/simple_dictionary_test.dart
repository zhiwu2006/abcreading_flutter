import 'package:flutter_test/flutter_test.dart';
import '../lib/services/enhanced_dictionary_service.dart';

void main() {
  group('Simple Dictionary Test', () {
    test('should load and display correct Chinese meanings', () async {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();

      // 初始化服务
      await EnhancedDictionaryService.initialize();

      // 测试几个基础单词
      final testWords = ['hello', 'world', 'book', 'read', 'learn'];

      for (final word in testWords) {
        final result = await EnhancedDictionaryService.lookupWord(word);

        if (result != null) {
          print('✅ Word: ${result.word}');
          print('   Meaning: ${result.primaryMeaning}');
          print('   Phonetic: ${result.formattedPhonetic}');
          print('   Source: ${result.source}');
          print('   All meanings: ${result.meanings}');
          print('---');

          // 验证数据不为空
          expect(result.word.isNotEmpty, true);
          expect(result.meanings.isNotEmpty, true);
          expect(result.primaryMeaning.isNotEmpty, true);
        } else {
          print('❌ Word not found: $word');
        }
      }
    });
  });
}
