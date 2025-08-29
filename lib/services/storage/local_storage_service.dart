import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/reading_preferences_entity.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  
  LocalStorageService._();

  Box<dynamic>? _lessonsBox;
  Box<dynamic>? _progressBox;
  Box<dynamic>? _preferencesBox;
  SharedPreferences? _prefs;

  // 初始化Hive数据库
  Future<void> init() async {
    try {
      _lessonsBox = await Hive.openBox('lessons');
      _progressBox = await Hive.openBox('progress');
      _preferencesBox = await Hive.openBox('preferences');
      _prefs = await SharedPreferences.getInstance();
      print('✅ LocalStorageService初始化成功');
    } catch (error) {
      print('❌ LocalStorageService初始化失败: $error');
    }
  }

  // 获取或创建会话ID
  String getOrCreateSessionId() {
    const key = 'session_id';
    String? sessionId = _prefs?.getString(key);
    
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _prefs?.setString(key, sessionId);
    }
    
    return sessionId;
  }

  // 获取课程列表 - 优先从SharedPreferences读取同步数据
  Future<List<LessonEntity>> getLessons() async {
    try {
      print('📚 开始加载课程数据...');
      
      // 1. 优先从SharedPreferences读取同步的缓存数据
      final prefs = await SharedPreferences.getInstance();
      final cachedLessonsJson = prefs.getString('cached_lessons');
      
      if (cachedLessonsJson != null && cachedLessonsJson.isNotEmpty) {
        print('📦 从SharedPreferences缓存加载课程数据');
        try {
          final List<dynamic> jsonList = jsonDecode(cachedLessonsJson);
          final lessons = jsonList
              .map((json) => LessonEntity.fromJson(json as Map<String, dynamic>))
              .toList();
          
          print('✅ 从SharedPreferences加载了 ${lessons.length} 个课程');
          
          // 同时保存到Hive以保持数据一致性
          await _saveLessonsToHive(lessons);
          
          return lessons;
        } catch (e) {
          print('❌ 解析SharedPreferences缓存数据失败: $e');
        }
      }
      
      // 2. 如果SharedPreferences没有数据，从Hive读取
      if (_lessonsBox != null) {
        print('📦 从Hive数据库加载课程数据');
        final lessonsData = _lessonsBox!.get('lessons');
        if (lessonsData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(lessonsData);
            final lessons = jsonList
                .map((json) => LessonEntity.fromJson(json as Map<String, dynamic>))
                .toList();
            
            print('✅ 从Hive加载了 ${lessons.length} 个课程');
            return lessons;
          } catch (e) {
            print('❌ 解析Hive数据失败: $e');
          }
        }
      }
      
      print('ℹ️ 没有找到本地课程数据，返回空列表');
      return [];
      
    } catch (error) {
      print('❌ 加载课程数据失败: $error');
      return [];
    }
  }

  // 兼容接口：与旧代码保持一致的本地加载方法
  Future<List<LessonEntity>> loadLessons() async {
    return getLessons();
  }

  // 保存课程列表 - 同时保存到Hive和SharedPreferences
  Future<bool> saveLessons(List<LessonEntity> lessons) async {
    try {
      print('💾 开始保存课程数据...');
      
      final jsonString = jsonEncode(lessons.map((lesson) => lesson.toJson()).toList());
      
      // 1. 保存到Hive
      bool hiveSuccess = await _saveLessonsToHive(lessons);
      
      // 2. 保存到SharedPreferences以保持数据一致性
      bool prefsSuccess = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        prefsSuccess = await prefs.setString('cached_lessons', jsonString);
        if (prefsSuccess) {
          print('✅ 课程数据已同步到SharedPreferences');
        }
      } catch (e) {
        print('⚠️ 同步到SharedPreferences失败: $e');
      }
      
      final success = hiveSuccess; // 主要以Hive保存结果为准
      if (success) {
        print('✅ 成功保存 ${lessons.length} 个课程');
      }
      
      return success;
    } catch (error) {
      print('❌ 保存课程数据失败: $error');
      return false;
    }
  }

  // 保存课程到Hive的辅助方法
  Future<bool> _saveLessonsToHive(List<LessonEntity> lessons) async {
    try {
      if (_lessonsBox != null) {
        final jsonString = jsonEncode(lessons.map((lesson) => lesson.toJson()).toList());
        await _lessonsBox!.put('lessons', jsonString);
        print('✅ 课程数据已保存到Hive');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 保存到Hive失败: $e');
      return false;
    }
  }

  // 清除课程缓存
  Future<bool> clearLessonsCache() async {
    try {
      // 清除Hive缓存
      if (_lessonsBox != null) {
        await _lessonsBox!.delete('lessons');
      }
      
      // 清除SharedPreferences缓存
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_lessons');
      
      print('✅ 课程缓存已清除');
      return true;
    } catch (error) {
      print('❌ 清除课程缓存失败: $error');
      return false;
    }
  }

  // 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    try {
      final stats = <String, dynamic>{
        'hive_initialized': _lessonsBox != null,
        'lessons_count': 0,
        'cache_size': 0,
        'last_updated': null,
      };

      if (_lessonsBox != null) {
        final lessonsData = _lessonsBox!.get('lessons');
        if (lessonsData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(lessonsData);
            stats['lessons_count'] = jsonList.length;
            stats['cache_size'] = lessonsData.length;
          } catch (e) {
            print('❌ 解析缓存统计失败: $e');
          }
        }
      }

      return stats;
    } catch (error) {
      print('❌ 获取缓存统计失败: $error');
      return {'error': error.toString()};
    }
  }

  // 保存学习进度
  Future<bool> saveProgress(Map<String, dynamic> progress) async {
    try {
      if (_progressBox != null) {
        await _progressBox!.put('progress', jsonEncode(progress));
        return true;
      }
      return false;
    } catch (error) {
      print('❌ 保存学习进度失败: $error');
      return false;
    }
  }

  // 获取学习进度
  Future<Map<String, dynamic>?> getProgress() async {
    try {
      if (_progressBox != null) {
        final progressData = _progressBox!.get('progress');
        if (progressData != null) {
          return Map<String, dynamic>.from(jsonDecode(progressData));
        }
      }
      return null;
    } catch (error) {
      print('❌ 获取学习进度失败: $error');
      return null;
    }
  }

  // 保存阅读偏好设置 - 简化版本
  Future<void> saveReadingPreferences(dynamic preferences) async {
    try {
      if (_preferencesBox != null) {
        String jsonString;
        if (preferences is ReadingPreferencesEntity) {
          jsonString = jsonEncode(preferences.toJson());
        } else if (preferences is Map<String, dynamic>) {
          jsonString = jsonEncode(preferences);
        } else {
          jsonString = jsonEncode({'default': 'preferences'});
        }
        await _preferencesBox!.put('reading_preferences', jsonString);
        print('✅ 阅读偏好设置已保存');
      }
    } catch (error) {
      print('❌ 保存阅读偏好设置失败: $error');
    }
  }

  // 加载阅读偏好设置 - 简化版本
  Future<dynamic> loadReadingPreferences() async {
    try {
      if (_preferencesBox != null) {
        final preferencesData = _preferencesBox!.get('reading_preferences');
        if (preferencesData != null) {
          final preferencesJson = jsonDecode(preferencesData) as Map<String, dynamic>;
          return ReadingPreferencesEntity.fromJson(preferencesJson);
        }
      }
      
      // 返回默认偏好设置
      final defaultPreferences = ReadingPreferencesEntity.defaultPreferences();
      await saveReadingPreferences(defaultPreferences);
      return defaultPreferences;
    } catch (error) {
      print('❌ 加载阅读偏好设置失败: $error');
      return ReadingPreferencesEntity.defaultPreferences();
    }
  }

  // 关闭数据库连接
  Future<void> close() async {
    try {
      await _lessonsBox?.close();
      await _progressBox?.close();
      await _preferencesBox?.close();
      print('✅ LocalStorageService已关闭');
    } catch (error) {
      print('❌ 关闭LocalStorageService失败: $error');
    }
  }
}