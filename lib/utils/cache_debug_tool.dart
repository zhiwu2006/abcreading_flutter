import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lesson.dart';
import '../services/lesson_manager_service.dart';

class CacheDebugTool {
  /// 检查缓存状态
  static Future<Map<String, dynamic>> checkCacheStatus() async {
    final result = <String, dynamic>{};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查 SharedPreferences 中的缓存数据
      final cachedLessonsJson = prefs.getString('cached_lessons');
      final lastSyncTime = prefs.getString('last_sync_time');
      
      result['has_cached_data'] = cachedLessonsJson != null && cachedLessonsJson.isNotEmpty;
      result['last_sync_time'] = lastSyncTime;
      
      if (cachedLessonsJson != null && cachedLessonsJson.isNotEmpty) {
        try {
          final List<dynamic> lessonsList = json.decode(cachedLessonsJson);
          result['cached_lessons_count'] = lessonsList.length;
          
          // 获取前几个课程的标题
          if (lessonsList.isNotEmpty) {
            final lessons = lessonsList.take(5).map((json) {
              try {
                final lesson = Lesson.fromJson(json);
                return {
                  'lesson': lesson.lesson,
                  'title': lesson.title,
                  'vocabulary_count': lesson.vocabulary.length,
                };
              } catch (e) {
                return {'error': 'Failed to parse lesson: $e'};
              }
            }).toList();
            result['sample_lessons'] = lessons;
          }
        } catch (e) {
          result['parse_error'] = e.toString();
        }
      } else {
        result['cached_lessons_count'] = 0;
      }
      
      // 检查 LessonManagerService 的状态
      final lessonManager = LessonManagerService.instance;
      result['current_source'] = lessonManager.currentSource.toString();
      
      // 尝试获取课程数据
      try {
        final lessons = await lessonManager.getLocalLessons();
        result['manager_lessons_count'] = lessons.length;
        
        if (lessons.isNotEmpty) {
          result['manager_sample_lessons'] = lessons.take(3).map((lesson) => {
            'lesson': lesson.lesson,
            'title': lesson.title,
          }).toList();
        }
      } catch (e) {
        result['manager_error'] = e.toString();
      }
      
    } catch (e) {
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// 强制重新加载缓存
  static Future<Map<String, dynamic>> forceReloadCache() async {
    final result = <String, dynamic>{};
    
    try {
      final lessonManager = LessonManagerService.instance;
      
      // 强制重新加载
      await lessonManager.forceReloadLocalCache();
      
      // 获取重新加载后的数据
      final lessons = await lessonManager.getLocalLessons();
      result['success'] = true;
      result['lessons_count'] = lessons.length;
      
      if (lessons.isNotEmpty) {
        result['sample_lessons'] = lessons.take(3).map((lesson) => {
          'lesson': lesson.lesson,
          'title': lesson.title,
        }).toList();
      }
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// 打印详细的调试信息
  static Future<void> printDebugInfo() async {
    print('🔍 ===== 缓存调试信息 =====');
    
    final status = await checkCacheStatus();
    
    print('📊 SharedPreferences 状态:');
    print('  - 有缓存数据: ${status['has_cached_data']}');
    print('  - 缓存课程数量: ${status['cached_lessons_count']}');
    print('  - 最后同步时间: ${status['last_sync_time']}');
    
    if (status['sample_lessons'] != null) {
      print('  - 缓存课程示例:');
      for (final lesson in status['sample_lessons']) {
        print('    * 课程${lesson['lesson']}: ${lesson['title']}');
      }
    }
    
    print('🎯 LessonManagerService 状态:');
    print('  - 当前数据源: ${status['current_source']}');
    print('  - 管理器课程数量: ${status['manager_lessons_count']}');
    
    if (status['manager_sample_lessons'] != null) {
      print('  - 管理器课程示例:');
      for (final lesson in status['manager_sample_lessons']) {
        print('    * 课程${lesson['lesson']}: ${lesson['title']}');
      }
    }
    
    if (status['error'] != null) {
      print('❌ 错误: ${status['error']}');
    }
    
    if (status['parse_error'] != null) {
      print('❌ 解析错误: ${status['parse_error']}');
    }
    
    if (status['manager_error'] != null) {
      print('❌ 管理器错误: ${status['manager_error']}');
    }
    
    print('🔍 ===== 调试信息结束 =====');
  }
}