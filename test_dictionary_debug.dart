import 'dart:convert';
import 'package:flutter/services.dart';
import 'lib/services/enhanced_dictionary_service.dart';

void main() async {
  print('🔍 Testing Dictionary Service...');

  try {
    // 初始化服务
    await EnhancedDictionaryService.initialize();
    print('✅ Service initialized');

    // 测试查询 hello
    final result = await EnhancedDictionaryService.lookupWord('hello');

    if (result != null) {
      print('✅ Found word: ${result.word}');
      print('📖 Primary meaning: ${result.primaryMeaning}');
      print('📝 All meanings: ${result.meanings}');
      print('🔊 Phonetic: ${result.formattedPhonetic}');
      print('🏷️ Part of speech: ${result.partOfSpeech}');
      print('📚 Source: ${result.source}');
    } else {
      print('❌ Word not found');
    }

    // 测试缓存统计
    final stats = EnhancedDictionaryService.getCacheStats();
    print('📊 Cache stats: $stats');
  } catch (e) {
    print('❌ Error: $e');
  }
}
