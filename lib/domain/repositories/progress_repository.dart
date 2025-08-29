import '../entities/progress_entity.dart';

/// 学习进度仓库接口
abstract class ProgressRepository {
  /// 获取用户学习进度
  Future<ProgressEntity?> getProgress({
    String? userId,
    String? sessionId,
  });

  /// 创建新的学习进度
  Future<ProgressEntity> createProgress({
    String? userId,
    String? sessionId,
    required int totalLessons,
  });

  /// 更新学习进度
  Future<ProgressEntity> updateProgress({
    String? userId,
    String? sessionId,
    required int lessonIndex,
    required int lessonNumber,
    int? totalLessons,
  });

  /// 清除学习进度
  Future<bool> clearProgress({
    String? userId,
    String? sessionId,
  });

  /// 获取或创建学习进度
  Future<ProgressEntity> getOrCreateProgress({
    String? userId,
    String? sessionId,
    required int totalLessons,
  });

  /// 同步进度到远程
  Future<bool> syncProgressToRemote(ProgressEntity progress);

  /// 从远程同步进度
  Future<ProgressEntity?> syncProgressFromRemote({
    String? userId,
    String? sessionId,
  });

  /// 获取进度统计信息
  Future<Map<String, dynamic>> getProgressStats({
    String? userId,
    String? sessionId,
  });
}
