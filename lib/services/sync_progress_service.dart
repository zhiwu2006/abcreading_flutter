import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'progress_service.dart';
import 'supabase_service.dart';

class SyncProgressService extends ProgressService {
  static final SyncProgressService _instance = SyncProgressService._internal();
  factory SyncProgressService() => _instance;
  SyncProgressService._internal();

  static SyncProgressService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService.instance;
  String? _sessionId;

  @override
  Future<void> initialize() async {
    await super.initialize();
    
    // 生成或获取会话ID
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');
    if (_sessionId == null) {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('session_id', _sessionId!);
    }

    // 如果Supabase已初始化，尝试同步数据
    if (_supabaseService.isInitialized) {
      await _syncFromCloud();
    }
  }

  @override
  Future<ProgressData?> loadProgress() async {
    // 先尝试从云端加载
    if (_supabaseService.isInitialized) {
      try {
        final cloudProgress = await _loadProgressFromCloud();
        if (cloudProgress != null) {
          // 同步到本地
          await _saveProgressToLocal(cloudProgress);
          return cloudProgress;
        }
      } catch (e) {
        print('从云端加载进度失败: $e');
      }
    }

    // 回退到本地加载
    return await super.loadProgress();
  }

  @override
  Future<void> updateCurrentLesson(int lessonIndex) async {
    // 先更新本地
    await super.updateCurrentLesson(lessonIndex);

    // 如果Supabase可用，同步到云端
    if (_supabaseService.isInitialized) {
      try {
        await _supabaseService.saveProgress(
          lessonNumber: lessonIndex + 1,
          progress: {
            'currentLessonIndex': lessonIndex,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          sessionId: _sessionId,
        );
        print('✅ 学习进度已同步到云端');
      } catch (e) {
        print('同步学习进度到云端失败: $e');
      }
    }
  }

  @override
  Future<void> updateLessonScore(String lessonId, int score) async {
    // 先更新本地
    await super.updateLessonScore(lessonId, score);

    // 如果Supabase可用，同步到云端
    if (_supabaseService.isInitialized) {
      try {
        final scores = await loadLessonScores();
        await _supabaseService.saveProgress(
          lessonNumber: int.tryParse(lessonId) ?? 0,
          progress: {
            'scores': scores,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          sessionId: _sessionId,
        );
        print('✅ 课程分数已同步到云端');
      } catch (e) {
        print('同步课程分数到云端失败: $e');
      }
    }
  }

  @override
  Future<bool> clearProgress() async {
    // 先清除本地
    final localResult = await super.clearProgress();

    // 如果Supabase可用，清除云端数据
    if (_supabaseService.isInitialized) {
      try {
        // 删除所有进度记录
        final allProgress = await _supabaseService.getAllProgress(sessionId: _sessionId);
        for (final progress in allProgress) {
          await _supabaseService.deleteProgress(
            lessonNumber: progress['lesson_number'],
            sessionId: _sessionId,
          );
        }
        print('✅ 云端进度已清除');
      } catch (e) {
        print('清除云端进度失败: $e');
      }
    }

    return localResult;
  }

  /// 从云端加载进度数据
  Future<ProgressData?> _loadProgressFromCloud() async {
    try {
      final allProgress = await _supabaseService.getAllProgress(sessionId: _sessionId);
      if (allProgress.isEmpty) return null;

      // 找到最新的进度记录
      allProgress.sort((a, b) => 
        DateTime.parse(b['updated_at']).compareTo(DateTime.parse(a['updated_at'])));
      
      final latestProgress = allProgress.first;
      final progressData = latestProgress['progress_data'] as Map<String, dynamic>;
      
      final currentLessonIndex = progressData['currentLessonIndex'] as int? ?? 0;
      
      return ProgressData(
        currentLessonIndex: currentLessonIndex,
        currentLessonNumber: currentLessonIndex + 1,
        totalLessons: 0,
      );
    } catch (e) {
      print('从云端加载进度失败: $e');
      return null;
    }
  }

  /// 将进度数据保存到本地
  Future<void> _saveProgressToLocal(ProgressData progressData) async {
    await updateCurrentLesson(progressData.currentLessonIndex);
  }

  /// 从云端同步所有数据
  Future<void> _syncFromCloud() async {
    try {
      print('🔄 开始从云端同步数据...');
      
      // 同步进度数据
      final cloudProgress = await _loadProgressFromCloud();
      if (cloudProgress != null) {
        await _saveProgressToLocal(cloudProgress);
        print('✅ 进度数据同步完成');
      }

      // 同步阅读偏好
      final preferences = await _supabaseService.getReadingPreferences(sessionId: _sessionId);
      if (preferences != null) {
        await _saveReadingPreferencesToLocal(preferences);
        print('✅ 阅读偏好同步完成');
      }

      print('🎉 云端数据同步完成');
    } catch (e) {
      print('从云端同步数据失败: $e');
    }
  }

  /// 将阅读偏好保存到本地
  Future<void> _saveReadingPreferencesToLocal(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reading_preferences', json.encode(preferences));
    } catch (e) {
      print('保存阅读偏好到本地失败: $e');
    }
  }

  /// 同步阅读偏好到云端
  Future<void> syncReadingPreferences(Map<String, dynamic> preferences) async {
    if (!_supabaseService.isInitialized) return;

    try {
      await _supabaseService.saveReadingPreferences(
        preferences: preferences,
        sessionId: _sessionId,
      );
      print('✅ 阅读偏好已同步到云端');
    } catch (e) {
      print('同步阅读偏好到云端失败: $e');
    }
  }

  /// 获取学习统计信息（结合本地和云端数据）
  Future<Map<String, dynamic>> getStudyStatistics() async {
    try {
      if (_supabaseService.isInitialized) {
        // 从云端获取统计信息
        final cloudStats = await _supabaseService.getStudyStatistics(sessionId: _sessionId);
        return cloudStats;
      } else {
        // 从本地获取统计信息
        return await super.getStudyStats();
      }
    } catch (e) {
      print('获取学习统计信息失败: $e');
      return await super.getStudyStats();
    }
  }

  /// 强制同步到云端
  Future<bool> forceSyncToCloud() async {
    if (!_supabaseService.isInitialized) {
      print('❌ Supabase未初始化，无法同步');
      return false;
    }

    try {
      print('🔄 开始强制同步到云端...');

      // 同步当前课程进度
      final currentLesson = await loadCurrentLesson();
      await _supabaseService.saveProgress(
        lessonNumber: currentLesson + 1,
        progress: {
          'currentLessonIndex': currentLesson,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        sessionId: _sessionId,
      );

      // 同步所有课程分数
      final scores = await loadLessonScores();
      for (final entry in scores.entries) {
        await _supabaseService.saveProgress(
          lessonNumber: int.tryParse(entry.key) ?? 0,
          progress: {
            'scores': {entry.key: entry.value},
            'updatedAt': DateTime.now().toIso8601String(),
          },
          sessionId: _sessionId,
        );
      }

      // 同步阅读偏好
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('reading_preferences');
      if (preferencesJson != null) {
        final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
        await _supabaseService.saveReadingPreferences(
          preferences: preferences,
          sessionId: _sessionId,
        );
      }

      print('🎉 强制同步到云端完成');
      return true;
    } catch (e) {
      print('强制同步到云端失败: $e');
      return false;
    }
  }

  /// 检查云端连接状态
  Future<bool> checkCloudConnection() async {
    if (!_supabaseService.isInitialized) return false;
    return await _supabaseService.testConnection();
  }

  /// 获取会话ID
  String? get sessionId => _sessionId;

  /// 是否启用云端同步
  bool get isCloudSyncEnabled => _supabaseService.isInitialized;
}