import 'lib/services/dictionary_service.dart';

void main() async {
  print('🧪 测试离线字典功能...');
  
  // 初始化字典
  await DictionaryService.initialize();
  
  // 测试查询几个单词
  final testWords = ['hello', 'world', 'good', 'about', 'accept'];
  
  for (final word in testWords) {
    final entry = await DictionaryService.lookupWord(word);
    if (entry != null) {
      print('✅ $word: ${entry.formattedTranslation}');
      print('   音标: ${entry.formattedPhonetic}');
      print('   标签: ${entry.learningTags.join(', ')}');
    } else {
      print('❌ 未找到单词: $word');
    }
    print('');
  }
  
  // 显示统计信息
  final stats = DictionaryService.getStatistics();
  print('📊 字典统计: ${stats['total']} 个单词，加载状态: ${stats['loaded'] == 1 ? '已加载' : '未加载'}');
}