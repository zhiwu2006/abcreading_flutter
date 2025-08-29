import '../entities/progress_entity.dart';
import '../entities/reading_preferences_entity.dart';
import '../repositories/progress_repository.dart';
import '../repositories/preferences_repository.dart';

/// 获取学习进度用例
class GetProgressUseCase {
  final ProgressRepository _repository;

  GetProgressUseCase(this._repository);

  Future<ProgressEntity?> call({
    String? userId,
    String? sessionId,
  }) async {
    return await _repository.getProgress(
      userId: userId,
      sessionId: sessionId,
    );
  }
}

/// 创建学习进度用例
class CreateProgressUseCase {
  final ProgressRepository _repository;

  CreateProgressUseCase(this._repository);

  Future<ProgressEntity> call({
    String? userId,
    String? sessionId,
    required int totalLessons,
  }) async {
    return await _repository.createProgress(
      userId: userId,
      sessionId: sessionId,
      totalLessons: totalLessons,
    );
  }
}

/// 更新学习进度用例
class UpdateProgressUseCase {
  final ProgressRepository _repository;

  UpdateProgressUseCase(this._repository);

  Future<ProgressEntity> call({
    String? userId,
    String? sessionId,
    required int lessonIndex,
    required int lessonNumber,
    int? totalLessons,
  }) async {
    return await _repository.updateProgress(
      userId: userId,
      sessionId: sessionId,
      lessonIndex: lessonIndex,
      lessonNumber: lessonNumber,
      totalLessons: totalLessons,
    );
  }
}

/// 清除学习进度用例
class ClearProgressUseCase {
  final ProgressRepository _repository;

  ClearProgressUseCase(this._repository);

  Future<bool> call({
    String? userId,
    String? sessionId,
  }) async {
    return await _repository.clearProgress(
      userId: userId,
      sessionId: sessionId,
    );
  }
}

/// 获取或创建学习进度用例
class GetOrCreateProgressUseCase {
  final ProgressRepository _repository;

  GetOrCreateProgressUseCase(this._repository);

  Future<ProgressEntity> call({
    String? userId,
    String? sessionId,
    required int totalLessons,
  }) async {
    return await _repository.getOrCreateProgress(
      userId: userId,
      sessionId: sessionId,
      totalLessons: totalLessons,
    );
  }
}

/// 同步进度到远程用例
class SyncProgressToRemoteUseCase {
  final ProgressRepository _repository;

  SyncProgressToRemoteUseCase(this._repository);

  Future<bool> call(ProgressEntity progress) async {
    return await _repository.syncProgressToRemote(progress);
  }
}

/// 从远程同步进度用例
class SyncProgressFromRemoteUseCase {
  final ProgressRepository _repository;

  SyncProgressFromRemoteUseCase(this._repository);

  Future<ProgressEntity?> call({
    String? userId,
    String? sessionId,
  }) async {
    return await _repository.syncProgressFromRemote(
      userId: userId,
      sessionId: sessionId,
    );
  }
}

/// 获取进度统计用例
class GetProgressStatsUseCase {
  final ProgressRepository _repository;

  GetProgressStatsUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    String? userId,
    String? sessionId,
  }) async {
    return await _repository.getProgressStats(
      userId: userId,
      sessionId: sessionId,
    );
  }
}

/// 重置学习进度用例
class ResetProgressUseCase {
  final ProgressRepository _repository;

  ResetProgressUseCase(this._repository);

  Future<ProgressEntity> call({
    String? userId,
    String? sessionId,
    required int totalLessons,
  }) async {
    try {
      print('🔄 重置学习进度...');
      
      // 先清除现有进度
      await _repository.clearProgress(
        userId: userId,
        sessionId: sessionId,
      );
      
      // 创建新的进度记录
      final newProgress = await _repository.createProgress(
        userId: userId,
        sessionId: sessionId,
        totalLessons: totalLessons,
      );
      
      print('✅ 学习进度已重置');
      return newProgress;
    } catch (error) {
      print('❌ 重置学习进度失败: $error');
      rethrow;
    }
  }
}

/// 跳转到指定课程用例
class JumpToLessonUseCase {
  final ProgressRepository _repository;

  JumpToLessonUseCase(this._repository);

  Future<ProgressEntity> call({
    String? userId,
    String? sessionId,
    required int targetLessonIndex,
    required int targetLessonNumber,
    required int totalLessons,
  }) async {
    try {
      print('🎯 跳转到第${targetLessonNumber}课...');
      
      // 验证目标课程索引
      if (targetLessonIndex < 0 || targetLessonIndex >= totalLessons) {
        throw Exception('无效的课程索引: $targetLessonIndex');
      }
      
      // 更新进度
      final updatedProgress = await _repository.updateProgress(
        userId: userId,
        sessionId: sessionId,
        lessonIndex: targetLessonIndex,
        lessonNumber: targetLessonNumber,
        totalLessons: totalLessons,
      );
      
      print('✅ 已跳转到第${targetLessonNumber}课');
      return updatedProgress;
    } catch (error) {
      print('❌ 跳转课程失败: $error');
      rethrow;
    }
  }
}

/// 获取阅读偏好设置用例
class GetReadingPreferencesUseCase {
  final PreferencesRepository _repository;

  GetReadingPreferencesUseCase(this._repository);

  Future<ReadingPreferencesEntity> call() async {
    return await _repository.getReadingPreferences();
  }
}

/// 保存阅读偏好设置用例
class SaveReadingPreferencesUseCase {
  final PreferencesRepository _repository;

  SaveReadingPreferencesUseCase(this._repository);

  Future<bool> call(ReadingPreferencesEntity preferences) async {
    return await _repository.saveReadingPreferences(preferences);
  }
}

/// 重置阅读偏好设置用例
class ResetReadingPreferencesUseCase {
  final PreferencesRepository _repository;

  ResetReadingPreferencesUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.resetToDefaults();
  }
}

/// 获取可用字体列表用例
class GetAvailableFontsUseCase {
  final PreferencesRepository _repository;

  GetAvailableFontsUseCase(this._repository);

  List<String> call() {
    return _repository.getAvailableFonts();
  }
}

/// 获取字体大小范围用例
class GetFontSizeRangeUseCase {
  final PreferencesRepository _repository;

  GetFontSizeRangeUseCase(this._repository);

  Map<String, double> call() {
    return _repository.getFontSizeRange();
  }
}

/// 更新字体大小用例
class UpdateFontSizeUseCase {
  final PreferencesRepository _repository;

  UpdateFontSizeUseCase(this._repository);

  Future<bool> call(double fontSize) async {
    try {
      // 获取当前偏好设置
      final currentPreferences = await _repository.getReadingPreferences();
      
      // 验证字体大小范围
      final fontSizeRange = _repository.getFontSizeRange();
      final minSize = fontSizeRange['min'] ?? 12.0;
      final maxSize = fontSizeRange['max'] ?? 48.0;
      
      if (fontSize < minSize || fontSize > maxSize) {
        throw Exception('字体大小超出范围: $minSize - $maxSize');
      }
      
      // 更新字体大小
      final updatedPreferences = currentPreferences.copyWith(fontSize: fontSize);
      
      return await _repository.saveReadingPreferences(updatedPreferences);
    } catch (error) {
      print('❌ 更新字体大小失败: $error');
      return false;
    }
  }
}

/// 更新字体类型用例
class UpdateFontFamilyUseCase {
  final PreferencesRepository _repository;

  UpdateFontFamilyUseCase(this._repository);

  Future<bool> call(String fontFamily) async {
    try {
      // 获取当前偏好设置
      final currentPreferences = await _repository.getReadingPreferences();
      
      // 验证字体类型
      final availableFonts = _repository.getAvailableFonts();
      if (!availableFonts.contains(fontFamily)) {
        throw Exception('不支持的字体类型: $fontFamily');
      }
      
      // 更新字体类型
      final updatedPreferences = currentPreferences.copyWith(fontFamily: fontFamily);
      
      return await _repository.saveReadingPreferences(updatedPreferences);
    } catch (error) {
      print('❌ 更新字体类型失败: $error');
      return false;
    }
  }
}

/// 切换生词高亮用例
class ToggleVocabularyHighlightUseCase {
  final PreferencesRepository _repository;

  ToggleVocabularyHighlightUseCase(this._repository);

  Future<bool> call(bool showHighlight) async {
    try {
      // 获取当前偏好设置
      final currentPreferences = await _repository.getReadingPreferences();
      
      // 更新生词高亮设置
      final updatedPreferences = currentPreferences.copyWith(
        highlightWords: showHighlight,
      );
      
      return await _repository.saveReadingPreferences(updatedPreferences);
    } catch (error) {
      print('❌ 切换生词高亮失败: $error');
      return false;
    }
  }
}

/// 批量更新阅读偏好设置用例
class BatchUpdatePreferencesUseCase {
  final PreferencesRepository _repository;

  BatchUpdatePreferencesUseCase(this._repository);

  Future<bool> call({
    double? fontSize,
    String? fontFamily,
    bool? highlightWords,
  }) async {
    try {
      // 获取当前偏好设置
      final currentPreferences = await _repository.getReadingPreferences();
      
      // 验证参数
      if (fontSize != null) {
        final fontSizeRange = _repository.getFontSizeRange();
        final minSize = fontSizeRange['min'] ?? 12.0;
        final maxSize = fontSizeRange['max'] ?? 48.0;
        
        if (fontSize < minSize || fontSize > maxSize) {
          throw Exception('字体大小超出范围: $minSize - $maxSize');
        }
      }
      
      if (fontFamily != null) {
        final availableFonts = _repository.getAvailableFonts();
        if (!availableFonts.contains(fontFamily)) {
          throw Exception('不支持的字体类型: $fontFamily');
        }
      }
      
      // 批量更新偏好设置
      final updatedPreferences = currentPreferences.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
        highlightWords: highlightWords,
      );
      
      return await _repository.saveReadingPreferences(updatedPreferences);
    } catch (error) {
      print('❌ 批量更新偏好设置失败: $error');
      return false;
    }
  }
}
