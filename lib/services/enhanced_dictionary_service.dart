import 'dart:convert';
// Removed local assets and widgets imports; only online EN-EN source kept
import 'package:http/http.dart' as http;
// Removed Youdao and config imports

/// 🔍 ENHANCED DICTIONARY: 增强词典服务
///
/// 功能特点：
/// - 仅英英（dictionaryapi.dev）
/// - 智能缓存机制，避免重复查询
/// - 支持音标、释义、例句、词性等信息
class EnhancedDictionaryService {
  static Map<String, DictionaryResult> _cache = {};
  static const int _cacheMaxSize = 1000;

  /// 初始化服务
  static Future<void> initialize() async {
    // no-op for EN-EN only
    return;
  }

  /// 查询单词 - 主要入口方法
  ///
  /// 1. 缓存
  /// 2. 英英（dictionaryapi.dev）
  static Future<DictionaryResult?> lookupWord(String word) async {
    if (word.isEmpty) return null;

    final cleanWord = _cleanWord(word);

    // 1) 缓存
    final cached = _cache[cleanWord];
    if (cached != null) return cached;

    // 2) 英英（Free Dictionary API）
    final onlineResult = await _lookupOnline(cleanWord);
    if (onlineResult != null && onlineResult.primaryMeaning.isNotEmpty) {
      _addToCache(cleanWord, onlineResult);
      print('🌐 Found online (EN-EN): $cleanWord');
      return onlineResult;
    }

    return null;
  }

  /// 查询英英（Free Dictionary API）
  static Future<DictionaryResult?> _lookupOnline(String word) async {
    try {
      final url =
          Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return DictionaryResult.fromApiResponse(word, data.first);
        }
      }
    } catch (e) {
      print('❌ Free Dictionary API error: $e');
    }

    return null;
  }


  /// 添加到缓存
  static void _addToCache(String word, DictionaryResult result) {
    if (_cache.length >= _cacheMaxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[word] = result;
  }

  /// 清理单词
  static String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
  }

  /// 清理缓存
  static void clearCache() {
    _cache.clear();
    print('🗑️ Dictionary cache cleared');
  }

  /// 获取缓存统计
  static Map<String, int> getCacheStats() {
    return {
      'cached_words': _cache.length,
    };
  }

  /// 释放资源
  static void dispose() {
    _cache.clear();
  }
}

/// 词典查询结果数据模型
class DictionaryResult {
  final String word;
  final String phonetic;
  final List<String> meanings;
  final String partOfSpeech;
  final List<String> examples;
  final String source;

  DictionaryResult({
    required this.word,
    required this.phonetic,
    required this.meanings,
    required this.partOfSpeech,
    required this.examples,
    required this.source,
  });

  /// 从本地词典数据创建
  factory DictionaryResult.fromLocalData(Map<String, dynamic> data) {
    return DictionaryResult(
      word: data['word'] ?? '',
      phonetic: data['phonetic'] ?? '',
      meanings: [data['translation'] ?? ''],
      partOfSpeech: data['tag'] ?? '',
      examples: [],
      source: 'Local Dictionary',
    );
  }

  /// 从 Free Dictionary API 响应创建
  factory DictionaryResult.fromApiResponse(
      String word, Map<String, dynamic> data) {
    final List<String> meanings = [];
    final List<String> examples = [];
    String phonetic = '';
    String partOfSpeech = '';

    // 提取音标
    if (data['phonetics'] != null && data['phonetics'].isNotEmpty) {
      for (final phoneticData in data['phonetics']) {
        if (phoneticData['text'] != null && phoneticData['text'].isNotEmpty) {
          phonetic = phoneticData['text'];
          break;
        }
      }
    }

    // 提取释义和例句
    if (data['meanings'] != null) {
      for (final meaning in data['meanings']) {
        if (partOfSpeech.isEmpty && meaning['partOfSpeech'] != null) {
          partOfSpeech = meaning['partOfSpeech'];
        }

        if (meaning['definitions'] != null) {
          for (final definition in meaning['definitions']) {
            if (definition['definition'] != null) {
              meanings.add(definition['definition']);
            }
            if (definition['example'] != null) {
              examples.add(definition['example']);
            }
          }
        }
      }
    }

    return DictionaryResult(
      word: word,
      phonetic: phonetic,
      meanings: meanings,
      partOfSpeech: partOfSpeech,
      examples: examples,
      source: 'Free Dictionary API',
    );
  }

  /// 获取格式化的音标
  String get formattedPhonetic {
    if (phonetic.isEmpty) return '';
    return phonetic.startsWith('/') ? phonetic : '/$phonetic/';
  }

  /// 获取主要释义
  String get primaryMeaning {
    return meanings.isNotEmpty ? meanings.first : '';
  }

  /// 获取第一个例句
  String get firstExample {
    return examples.isNotEmpty ? examples.first : '';
  }

  /// 是否有音标
  bool get hasPhonetic => phonetic.isNotEmpty;

  /// 是否有例句
  bool get hasExamples => examples.isNotEmpty;

  @override
  String toString() {
    return 'DictionaryResult(word: $word, meanings: ${meanings.length}, source: $source)';
  }
}
