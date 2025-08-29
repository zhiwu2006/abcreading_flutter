import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressData {
  final int currentLessonIndex;
  final int currentLessonNumber;
  final int totalLessons;

  ProgressData({
    required this.currentLessonIndex,
    required this.currentLessonNumber,
    required this.totalLessons,
  });
}

class ProgressService {
  static const String _currentLessonKey = 'current_lesson';
  static const String _lessonScoresKey = 'lesson_scores';
  static const String _lessonProgressKey = 'lesson_progress';
  static const String _totalProgressKey = 'total_progress';

  // 初始化服务
  Future<void> initialize() async {
    // 确保SharedPreferences可用
    await SharedPreferences.getInstance();
  }

  // 加载学习进度
  Future<ProgressData?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLessonIndex = prefs.getInt(_currentLessonKey) ?? 0;
      return ProgressData(
        currentLessonIndex: currentLessonIndex,
        currentLessonNumber: currentLessonIndex + 1,
        totalLessons: 0, // 将在调用时设置
      );
    } catch (e) {
      return null;
    }
  }

  // 清除所有进度
  Future<bool> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentLessonKey);
      await prefs.remove(_lessonScoresKey);
      await prefs.remove(_lessonProgressKey);
      await prefs.remove(_totalProgressKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 加载当前课程进度
  Future<int> loadCurrentLesson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentLessonKey) ?? 0;
  }

  // 更新当前课程
  Future<void> updateCurrentLesson(int lessonIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentLessonKey, lessonIndex);
  }

  // 加载课程分数
  Future<Map<String, int>> loadLessonScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_lessonScoresKey);
    if (scoresJson != null) {
      final Map<String, dynamic> decoded = json.decode(scoresJson);
      return decoded.map((key, value) => MapEntry(key, value as int));
    }
    return {};
  }

  // 更新课程分数
  Future<void> updateLessonScore(String lessonId, int score) async {
    final scores = await loadLessonScores();
    scores[lessonId] = score;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lessonScoresKey, json.encode(scores));
  }

  // 加载课程进度（每个课程的完成状态）
  Future<Map<String, bool>> loadLessonProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_lessonProgressKey);
    if (progressJson != null) {
      final Map<String, dynamic> decoded = json.decode(progressJson);
      return decoded.map((key, value) => MapEntry(key, value as bool));
    }
    return {};
  }

  // 更新课程进度
  Future<void> updateLessonProgress(String lessonId, bool completed) async {
    final progress = await loadLessonProgress();
    progress[lessonId] = completed;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lessonProgressKey, json.encode(progress));
  }

  // 计算总体进度百分比
  Future<double> calculateTotalProgress(int totalLessons) async {
    final progress = await loadLessonProgress();
    final completedCount = progress.values.where((completed) => completed).length;
    return totalLessons > 0 ? completedCount / totalLessons : 0.0;
  }

  // 获取课程分数
  Future<int> getLessonScore(String lessonId) async {
    final scores = await loadLessonScores();
    return scores[lessonId] ?? 0;
  }

  // 检查课程是否完成
  Future<bool> isLessonCompleted(String lessonId) async {
    final progress = await loadLessonProgress();
    return progress[lessonId] ?? false;
  }

  // 获取已完成课程数量
  Future<int> getCompletedLessonsCount() async {
    final progress = await loadLessonProgress();
    return progress.values.where((completed) => completed).length;
  }


  // 导出进度数据
  Future<Map<String, dynamic>> exportProgress() async {
    final currentLesson = await loadCurrentLesson();
    final scores = await loadLessonScores();
    final progress = await loadLessonProgress();
    
    return {
      'currentLesson': currentLesson,
      'scores': scores,
      'progress': progress,
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  // 导入进度数据
  Future<void> importProgress(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (data.containsKey('currentLesson')) {
      await prefs.setInt(_currentLessonKey, data['currentLesson']);
    }
    
    if (data.containsKey('scores')) {
      await prefs.setString(_lessonScoresKey, json.encode(data['scores']));
    }
    
    if (data.containsKey('progress')) {
      await prefs.setString(_lessonProgressKey, json.encode(data['progress']));
    }
  }

  // 获取学习统计信息
  Future<Map<String, dynamic>> getStudyStats() async {
    final scores = await loadLessonScores();
    final progress = await loadLessonProgress();
    
    final completedLessons = progress.values.where((completed) => completed).length;
    final totalScore = scores.values.fold(0, (sum, score) => sum + score);
    final averageScore = scores.isNotEmpty ? totalScore / scores.length : 0.0;
    
    return {
      'completedLessons': completedLessons,
      'totalLessons': progress.length,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'completionRate': progress.isNotEmpty ? completedLessons / progress.length : 0.0,
    };
  }

  // 重置特定课程的进度
  Future<void> resetLessonProgress(String lessonId) async {
    final scores = await loadLessonScores();
    final progress = await loadLessonProgress();
    
    scores.remove(lessonId);
    progress.remove(lessonId);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lessonScoresKey, json.encode(scores));
    await prefs.setString(_lessonProgressKey, json.encode(progress));
  }

  // 标记课程为已完成（当测验分数达到一定标准时）
  Future<void> markLessonCompleted(String lessonId, int score) async {
    await updateLessonScore(lessonId, score);
    // 如果分数达到60分以上，标记为完成
    if (score >= 60) {
      await updateLessonProgress(lessonId, true);
    }
  }

  // 获取下一个未完成的课程索引
  Future<int> getNextIncompleteLesson(List<dynamic> lessons) async {
    final progress = await loadLessonProgress();
    
    for (int i = 0; i < lessons.length; i++) {
      final lessonId = lessons[i]['id'] ?? i.toString();
      if (!(progress[lessonId] ?? false)) {
        return i;
      }
    }
    
    // 如果所有课程都完成了，返回最后一个课程
    return lessons.length - 1;
  }
}