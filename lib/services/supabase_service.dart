import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import '../models/lesson.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseService get instance => _instance;

  late SupabaseClient _supabase;
  bool _initialized = false;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await _instance._initialize(url: url, anonKey: anonKey);
  }

  Future<void> _initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    
    _supabase = Supabase.instance.client;
    _initialized = true;
  }

  bool isUserSignedIn() {
    if (!_initialized) return false;
    return _supabase.auth.currentUser != null;
  }

  Future<void> signInAnonymously() async {
    try {
      await _supabase.auth.signInAnonymously();
    } catch (e) {
      print('匿名登录失败: $e');
      rethrow;
    }
  }

  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>?> getPreferences({required String userId}) async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      print('获取用户偏好失败: $e');
      return null;
    }
  }

  Future<void> savePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _supabase
          .from('user_preferences')
          .upsert({
            'user_id': userId,
            'preferences': preferences,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('保存用户偏好失败: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatistics({required String userId}) async {
    try {
      final progressResponse = await _supabase
          .from('user_progress')
          .select('lesson_id')
          .eq('user_id', userId);

      final completedLessons = progressResponse.length;
      final totalLessons = await getLessonCount();

      final scoresResponse = await _supabase
          .from('user_progress')
          .select('score')
          .eq('user_id', userId);

      double averageScore = 0;
      if (scoresResponse.isNotEmpty) {
        final scores = scoresResponse
            .map((item) => (item['score'] as num?)?.toDouble() ?? 0)
            .toList();
        averageScore = scores.reduce((a, b) => a + b) / scores.length;
      }

      return {
        'completed_lessons': completedLessons,
        'total_lessons': totalLessons,
        'completion_rate': totalLessons > 0 ? (completedLessons / totalLessons * 100).round() : 0,
        'average_score': averageScore.round(),
      };
    } catch (e) {
      print('获取用户统计信息失败: $e');
      return {
        'completed_lessons': 0,
        'total_lessons': 0,
        'completion_rate': 0,
        'average_score': 0,
      };
    }
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase未初始化，请先调用initialize方法');
    }
    return _supabase;
  }

  bool get isInitialized => _initialized;

  Future<List<Lesson>> getLessons() async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .order('lesson_number');
      
      return (response as List)
          .map((json) => Lesson.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      print('获取课程列表失败: $e');
      return [];
    }
  }

  Future<Lesson?> getLessonByNumber(int lessonNumber) async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('lesson_number', lessonNumber)
          .single();
      
      return Lesson.fromSupabaseJson(response);
    } catch (e) {
      print('获取课程失败: $e');
      return null;
    }
  }

  Future<int> getLessonCount() async {
    try {
      final response = await _supabase
          .from('lessons')
          .count();
      
      return response;
    } catch (e) {
      print('获取课程总数失败: $e');
      return 0;
    }
  }

  Future<bool> saveProgress({
    required int lessonNumber,
    required Map<String, dynamic> progress,
    String? sessionId,
  }) async {
    try {
      final data = {
        'lesson_number': lessonNumber,
        'progress_data': progress,
        'session_id': sessionId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('progress')
          .upsert(data);
      
      return true;
    } catch (e) {
      print('保存学习进度失败: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProgress({
    required int lessonNumber,
    String? sessionId,
  }) async {
    try {
      var query = _supabase
          .from('progress')
          .select()
          .eq('lesson_number', lessonNumber);

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      final response = await query.maybeSingle();
      
      return response?['progress_data'] as Map<String, dynamic>?;
    } catch (e) {
      print('获取学习进度失败: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProgress({String? sessionId}) async {
    try {
      var query = _supabase
          .from('progress')
          .select();

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      final response = await query.order('lesson_number');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('获取所有学习进度失败: $e');
      return [];
    }
  }

  Future<bool> deleteProgress({
    required int lessonNumber,
    String? sessionId,
  }) async {
    try {
      var query = _supabase
          .from('progress')
          .delete()
          .eq('lesson_number', lessonNumber);

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      await query;
      return true;
    } catch (e) {
      print('删除学习进度失败: $e');
      return false;
    }
  }

  Future<bool> saveReadingPreferences({
    required Map<String, dynamic> preferences,
    String? sessionId,
  }) async {
    try {
      final data = {
        'preferences_data': preferences,
        'session_id': sessionId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('reading_preferences')
          .upsert(data);
      
      return true;
    } catch (e) {
      print('保存阅读偏好失败: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getReadingPreferences({String? sessionId}) async {
    try {
      var query = _supabase
          .from('reading_preferences')
          .select();

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      final response = await query.maybeSingle();
      
      return response?['preferences_data'] as Map<String, dynamic>?;
    } catch (e) {
      print('获取阅读偏好失败: $e');
      return null;
    }
  }

  Future<bool> insertLessons(List<Lesson> lessons) async {
    try {
      final data = lessons.map((lesson) => lesson.toSupabaseJson()).toList();
      
      await _supabase
          .from('lessons')
          .insert(data);
      
      return true;
    } catch (e) {
      print('批量插入课程数据失败: $e');
      return false;
    }
  }

  Future<bool> updateLesson(Lesson lesson) async {
    try {
      await _supabase
          .from('lessons')
          .update(lesson.toSupabaseJson())
          .eq('lesson_number', lesson.lesson);
      
      return true;
    } catch (e) {
      print('更新课程数据失败: $e');
      return false;
    }
  }

  Future<bool> deleteLesson(int lessonNumber) async {
    try {
      await _supabase
          .from('lessons')
          .delete()
          .eq('lesson_number', lessonNumber);
      
      return true;
    } catch (e) {
      print('删除课程失败: $e');
      return false;
    }
  }

  Future<List<Lesson>> searchLessons(String keyword) async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .or('title.ilike.%$keyword%,content.ilike.%$keyword%')
          .order('lesson_number');
      
      return (response as List)
          .map((json) => Lesson.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      print('搜索课程失败: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudyStatistics({String? sessionId}) async {
    try {
      final totalLessons = await getLessonCount();
      
      var progressQuery = _supabase
          .from('progress')
          .select('lesson_number');

      if (sessionId != null) {
        progressQuery = progressQuery.eq('session_id', sessionId);
      }

      final progressResponse = await progressQuery;
      final completedLessons = progressResponse.length;

      final completionRate = totalLessons > 0 
          ? (completedLessons / totalLessons * 100).round()
          : 0;

      return {
        'total_lessons': totalLessons,
        'completed_lessons': completedLessons,
        'completion_rate': completionRate,
        'remaining_lessons': totalLessons - completedLessons,
      };
    } catch (e) {
      print('获取学习统计信息失败: $e');
      return {
        'total_lessons': 0,
        'completed_lessons': 0,
        'completion_rate': 0,
        'remaining_lessons': 0,
      };
    }
  }

  Future<bool> cleanupExpiredData({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysToKeep))
          .toIso8601String();

      await _supabase
          .from('progress')
          .delete()
          .lt('updated_at', cutoffDate);

      await _supabase
          .from('reading_preferences')
          .delete()
          .lt('updated_at', cutoffDate);

      return true;
    } catch (e) {
      print('清理过期数据失败: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      await _supabase
          .from('lessons')
          .select('lesson_number')
          .limit(1);
      
      return true;
    } catch (e) {
      print('数据库连接测试失败: $e');
      return false;
    }
  }

  void dispose() {
    _initialized = false;
  }
}