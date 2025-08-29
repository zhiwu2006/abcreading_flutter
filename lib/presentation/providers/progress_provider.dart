import 'package:flutter/foundation.dart';
import '../../domain/entities/progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/progress_usecases.dart';
import '../../services/storage/local_storage_service.dart';

/// 学习进度状态管理Provider
class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _repository;
  
  // 用例
  late final GetProgressUseCase _getProgressUseCase;
  late final CreateProgressUseCase _createProgressUseCase;
  late final UpdateProgressUseCase _updateProgressUseCase;
  late final ClearProgressUseCase _clearProgressUseCase;
  late final GetOrCreateProgressUseCase _getOrCreateProgressUseCase;
  late final ResetProgressUseCase _resetProgressUseCase;
  late final JumpToLessonUseCase _jumpToLessonUseCase;
  late final GetProgressStatsUseCase _getProgressStatsUseCase;

  ProgressProvider({required ProgressRepository progressRepository})
      : _repository = progressRepository {
    _initializeUseCases();
    _initializeSession();
  }

  /// 初始化用例
  void _initializeUseCases() {
    _getProgressUseCase = GetProgressUseCase(_repository);
    _createProgressUseCase = CreateProgressUseCase(_repository);
    _updateProgressUseCase = UpdateProgressUseCase(_repository);
    _clearProgressUseCase = ClearProgressUseCase(_repository);
    _getOrCreateProgressUseCase = GetOrCreateProgressUseCase(_repository);
    _resetProgressUseCase = ResetProgressUseCase(_repository);
    _jumpToLessonUseCase = JumpToLessonUseCase(_repository);
    _getProgressStatsUseCase = GetProgressStatsUseCase(_repository);
  }

  /// 初始化会话
  void _initializeSession() {
    _sessionId = LocalStorageService.instance.getOrCreateSessionId();
    print('📱 学习会话ID: $_sessionId');
  }

  // 状态变量
  ProgressEntity? _progress;
  String? _userId;
  String? _sessionId;
  bool _isLoading = false;
  bool _isSyncing = false;
  String _error = '';
  Map<String, dynamic> _stats = {};
  
  // Getters
  ProgressEntity? get progress => _progress;
  String? get userId => _userId;
  String? get sessionId => _sessionId;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String get error => _error;
  Map<String, dynamic> get stats => _stats;
  bool get hasProgress => _progress != null;
  bool get hasError => _error.isNotEmpty;
  
  // 进度相关的便捷getters
  int get currentLessonIndex => _progress?.currentLessonIndex ?? 0;
  int get currentLessonNumber => _progress?.currentLessonNumber ?? 1;
  int get totalLessons => _progress?.totalLessons ?? 0;
  double get progressPercentage => _progress?.progressPercentage ?? 0.0;
  int get remainingLessons => _progress?.remainingLessons ?? 0;
  bool get isCompleted => _progress?.isCompleted ?? false;
  DateTime? get lastAccessedAt => _progress?.lastAccessedAt;

  /// 设置用户ID
  void setUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      print('👤 用户ID已更新: $userId');
      notifyListeners();
    }
  }

  /// 获取或创建学习进度
  Future<ProgressEntity?> getOrCreateProgress(int totalLessons) async {
    if (_isLoading) return _progress;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📊 获取或创建学习进度...');
      print('用户状态: ${_userId != null ? '已登录' : '匿名用户'}');
      print('总课程数: $totalLessons');
      
      final progress = await _getOrCreateProgressUseCase(
        userId: _userId,
        sessionId: _sessionId,
        totalLessons: totalLessons,
      );
      
      _progress = progress;
      await _updateStats();
      
      print('✅ 学习进度已准备就绪');
      print('当前进度: 第${progress.currentLessonNumber}课 (${progress.progressPercentage.toStringAsFixed(1)}%)');
      
      return progress;
    } catch (error) {
      _setError('获取学习进度失败: $error');
      print('❌ 获取学习进度失败: $error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新学习进度
  Future<bool> updateProgress({
    required int lessonIndex,
    required int lessonNumber,
    int? totalLessons,
  }) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('💾 更新学习进度: 第${lessonNumber}课 (索引${lessonIndex})');
      
      final updatedProgress = await _updateProgressUseCase(
        userId: _userId,
        sessionId: _sessionId,
        lessonIndex: lessonIndex,
        lessonNumber: lessonNumber,
        totalLessons: totalLessons,
      );
      
      _progress = updatedProgress;
      await _updateStats();
      
      print('✅ 学习进度已更新');
      print('新进度: 第${updatedProgress.currentLessonNumber}课 (${updatedProgress.progressPercentage.toStringAsFixed(1)}%)');
      
      return true;
    } catch (error) {
      _setError('更新学习进度失败: $error');
      print('❌ 更新学习进度失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 跳转到指定课程
  Future<bool> jumpToLesson({
    required int targetLessonIndex,
    required int targetLessonNumber,
    required int totalLessons,
  }) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🎯 跳转到第${targetLessonNumber}课...');
      
      final updatedProgress = await _jumpToLessonUseCase(
        userId: _userId,
        sessionId: _sessionId,
        targetLessonIndex: targetLessonIndex,
        targetLessonNumber: targetLessonNumber,
        totalLessons: totalLessons,
      );
      
      _progress = updatedProgress;
      await _updateStats();
      
      print('✅ 已跳转到第${targetLessonNumber}课');
      
      return true;
    } catch (error) {
      _setError('跳转课程失败: $error');
      print('❌ 跳转课程失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 重置学习进度
  Future<bool> resetProgress(int totalLessons) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔄 重置学习进度...');
      
      final newProgress = await _resetProgressUseCase(
        userId: _userId,
        sessionId: _sessionId,
        totalLessons: totalLessons,
      );
      
      _progress = newProgress;
      await _updateStats();
      
      print('✅ 学习进度已重置');
      
      return true;
    } catch (error) {
      _setError('重置学习进度失败: $error');
      print('❌ 重置学习进度失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 清除学习进度
  Future<bool> clearProgress() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🗑️ 清除学习进度...');
      
      final success = await _clearProgressUseCase(
        userId: _userId,
        sessionId: _sessionId,
      );
      
      if (success) {
        _progress = null;
        _stats.clear();
        print('✅ 学习进度已清除');
        return true;
      } else {
        _setError('清除学习进度失败');
        return false;
      }
    } catch (error) {
      _setError('清除学习进度失败: $error');
      print('❌ 清除学习进度失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 下一课
  Future<bool> nextLesson() async {
    if (_progress == null) return false;
    
    final nextIndex = _progress!.currentLessonIndex + 1;
    final nextNumber = _progress!.currentLessonNumber + 1;
    
    if (nextIndex >= _progress!.totalLessons) {
      print('ℹ️ 已经是最后一课了');
      return false;
    }
    
    return await updateProgress(
      lessonIndex: nextIndex,
      lessonNumber: nextNumber,
      totalLessons: _progress!.totalLessons,
    );
  }

  /// 上一课
  Future<bool> previousLesson() async {
    if (_progress == null) return false;
    
    final prevIndex = _progress!.currentLessonIndex - 1;
    final prevNumber = _progress!.currentLessonNumber - 1;
    
    if (prevIndex < 0) {
      print('ℹ️ 已经是第一课了');
      return false;
    }
    
    return await updateProgress(
      lessonIndex: prevIndex,
      lessonNumber: prevNumber,
      totalLessons: _progress!.totalLessons,
    );
  }

  /// 检查是否可以进入下一课
  bool canGoNext() {
    if (_progress == null) return false;
    return _progress!.currentLessonIndex < _progress!.totalLessons - 1;
  }

  /// 检查是否可以回到上一课
  bool canGoPrevious() {
    if (_progress == null) return false;
    return _progress!.currentLessonIndex > 0;
  }

  /// 获取进度描述
  String getProgressDescription() {
    if (_progress == null) return '暂无进度';
    
    if (_progress!.isCompleted) {
      return '已完成所有课程！';
    }
    
    return '第${_progress!.currentLessonNumber}课 / 共${_progress!.totalLessons}课 '
           '(${_progress!.progressPercentage.toStringAsFixed(1)}%)';
  }

  /// 获取剩余课程描述
  String getRemainingDescription() {
    if (_progress == null) return '';
    
    if (_progress!.isCompleted) {
      return '恭喜完成所有课程！';
    }
    
    return '还有${_progress!.remainingLessons}课待学习';
  }

  /// 更新统计信息
  Future<void> _updateStats() async {
    try {
      _stats = await _getProgressStatsUseCase(
        userId: _userId,
        sessionId: _sessionId,
      );
    } catch (error) {
      print('⚠️ 更新统计信息失败: $error');
    }
  }

  /// 获取学习时长（模拟）
  Duration getStudyDuration() {
    if (_progress == null) return Duration.zero;
    
    final now = DateTime.now();
    final created = _progress!.createdAt;
    return now.difference(created);
  }

  /// 获取平均每课学习时间（模拟）
  Duration getAverageTimePerLesson() {
    if (_progress == null || _progress!.currentLessonIndex == 0) {
      return Duration.zero;
    }
    
    final totalDuration = getStudyDuration();
    final completedLessons = _progress!.currentLessonIndex;
    
    return Duration(
      milliseconds: totalDuration.inMilliseconds ~/ completedLessons,
    );
  }

  /// 预估完成时间
  DateTime? getEstimatedCompletionTime() {
    if (_progress == null || _progress!.isCompleted) return null;
    
    final averageTime = getAverageTimePerLesson();
    if (averageTime == Duration.zero) return null;
    
    final remainingTime = Duration(
      milliseconds: averageTime.inMilliseconds * _progress!.remainingLessons,
    );
    
    return DateTime.now().add(remainingTime);
  }

  /// 获取学习统计摘要
  Map<String, dynamic> getStudySummary() {
    if (_progress == null) {
      return {
        'has_progress': false,
        'message': '暂无学习记录',
      };
    }
    
    final studyDuration = getStudyDuration();
    final averageTime = getAverageTimePerLesson();
    final estimatedCompletion = getEstimatedCompletionTime();
    
    return {
      'has_progress': true,
      'current_lesson': _progress!.currentLessonNumber,
      'total_lessons': _progress!.totalLessons,
      'progress_percentage': _progress!.progressPercentage,
      'remaining_lessons': _progress!.remainingLessons,
      'is_completed': _progress!.isCompleted,
      'study_duration_days': studyDuration.inDays,
      'study_duration_hours': studyDuration.inHours,
      'average_time_per_lesson_minutes': averageTime.inMinutes,
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'last_accessed': _progress!.lastAccessedAt.toIso8601String(),
      'created_at': _progress!.createdAt.toIso8601String(),
    };
  }

  /// 刷新进度数据
  Future<void> refresh() async {
    if (_progress != null) {
      await getOrCreateProgress(_progress!.totalLessons);
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _error = '';
    notifyListeners();
  }

  /// 清除所有状态
  void clearAll() {
    _progress = null;
    _userId = null;
    _isLoading = false;
    _isSyncing = false;
    _error = '';
    _stats.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}