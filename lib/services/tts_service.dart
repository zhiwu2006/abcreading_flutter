import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 文本转语音服务
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  String? _currentSpeakingId;
  
  /// 初始化TTS服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _flutterTts = FlutterTts();
      
      // 设置语言为英语
      await _flutterTts!.setLanguage("en-US");
      
      // 设置语音参数
      await _flutterTts!.setSpeechRate(0.5); // 语速
      await _flutterTts!.setVolume(1.0); // 音量
      await _flutterTts!.setPitch(1.0); // 音调
      
      // 设置回调
      _flutterTts!.setCompletionHandler(() {
        _currentSpeakingId = null;
      });
      
      _flutterTts!.setErrorHandler((msg) {
        debugPrint('TTS错误: $msg');
        _currentSpeakingId = null;
      });
      
      _isInitialized = true;
      debugPrint('TTS服务初始化成功');
    } catch (e) {
      debugPrint('TTS服务初始化失败: $e');
    }
  }
  
  /// 朗读文本
  Future<void> speak(String text, {String? id}) async {
    if (!_isInitialized || _flutterTts == null) {
      await initialize();
    }
    
    if (_flutterTts == null) return;
    
    try {
      // 如果正在朗读相同的ID，则停止
      if (_currentSpeakingId == id && id != null) {
        await stop();
        return;
      }
      
      // 停止当前朗读
      await stop();
      
      _currentSpeakingId = id;
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('朗读失败: $e');
      _currentSpeakingId = null;
    }
  }
  
  /// 朗读单词（稍慢语速）
  Future<void> speakWord(String word, {String? id}) async {
    if (!_isInitialized || _flutterTts == null) {
      await initialize();
    }
    
    if (_flutterTts == null) return;
    
    try {
      // 清理单词，移除标点符号
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.isEmpty) return;
      
      // 如果正在朗读相同的ID，则停止
      if (_currentSpeakingId == id && id != null) {
        await stop();
        return;
      }
      
      await stop();
      
      // 设置较慢的语速用于单词朗读
      await _flutterTts!.setSpeechRate(0.4);
      
      _currentSpeakingId = id;
      await _flutterTts!.speak(cleanWord);
      
      // 恢复正常语速
      await _flutterTts!.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('单词朗读失败: $e');
      _currentSpeakingId = null;
    }
  }
  
  /// 慢速朗读句子
  Future<void> speakSentenceSlow(String sentence, {String? id}) async {
    if (!_isInitialized || _flutterTts == null) {
      await initialize();
    }
    
    if (_flutterTts == null) return;
    
    try {
      if (_currentSpeakingId == id && id != null) {
        await stop();
        return;
      }
      
      await stop();
      
      // 设置慢速
      await _flutterTts!.setSpeechRate(0.3);
      
      _currentSpeakingId = id;
      await _flutterTts!.speak(sentence);
      
      // 恢复正常语速
      await _flutterTts!.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('慢速朗读失败: $e');
      _currentSpeakingId = null;
    }
  }
  
  /// 快速朗读句子
  Future<void> speakSentenceFast(String sentence, {String? id}) async {
    if (!_isInitialized || _flutterTts == null) {
      await initialize();
    }
    
    if (_flutterTts == null) return;
    
    try {
      if (_currentSpeakingId == id && id != null) {
        await stop();
        return;
      }
      
      await stop();
      
      // 设置快速
      await _flutterTts!.setSpeechRate(0.8);
      
      _currentSpeakingId = id;
      await _flutterTts!.speak(sentence);
      
      // 恢复正常语速
      await _flutterTts!.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('快速朗读失败: $e');
      _currentSpeakingId = null;
    }
  }
  
  /// 停止朗读
  Future<void> stop() async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.stop();
        _currentSpeakingId = null;
      } catch (e) {
        debugPrint('停止朗读失败: $e');
      }
    }
  }
  
  /// 检查是否正在朗读指定ID的内容
  bool isSpeakingId(String id) {
    return _currentSpeakingId == id;
  }
  
  /// 检查是否正在朗读
  bool get isSpeaking => _currentSpeakingId != null;
  
  /// 获取当前朗读的ID
  String? get currentSpeakingId => _currentSpeakingId;
  
  /// 释放资源
  void dispose() {
    _flutterTts?.stop();
    _currentSpeakingId = null;
  }
}