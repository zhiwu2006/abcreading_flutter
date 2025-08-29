import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/storage/local_storage_service.dart';

/// 学习进度仓库实现类
class ProgressRepositoryImpl implements ProgressRepository {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final Connectivity _connectivity;
  final Uuid _uuid = const Uuid();

  ProgressRepositoryImpl({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    required Connectivity connectivity,
  }) : _supabaseService = supabaseService,
       _localStorageService = localStorageService,
       _connectivity = connectivity;

  @override
  Future<ProgressEntity?> getProgress({
    String? userId,
    String? sessionId,
  }) async {
    try {
      print('📊 获取学习进度...');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 优先从远程获取
          final remoteProgress = await _supabaseService.getUserProgress(
            userId: userId,
            sessionId: sessionId,
          );
          
          if (remoteProgress != null) {
            print('✅ 从远程数据库获取到学习进度');
            // 同步到本地
            await _localStorageService.saveProgress(remoteProgress);
            return remoteProgress;
          }
        } catch (error) {
          print('⚠️ 从远程获取进度失败: $error，尝试从本地获取');
        }
      }
      
      // 从本地获取
      final localProgress = await _localStorageService.loadProgress();
      if (localProgress != null) {
        print('✅ 从本地存储获取到学习进度');
        return localProgress;
      }
      
      print('ℹ️ 没有找到学习进度记录');
      return null;
    } catch (error) {
      print('❌ 获取学习进度失败: $error');
      return null;
    }
  }

  @override
  Future<ProgressEntity> createProgress({
    String? userId,
    String? sessionId,
    required int totalLessons,
  }) async {
    try {
      print('📝 创建新的学习进度记录...');
      
      // 生成进度ID
      final progressId = _uuid.v4();
      
      // 创建进度实体
      final progress = ProgressEntity.create(
        id: progressId,
        userId: userId,
        sessionId: sessionId,
        totalLessons: totalLessons,
      );
      
      // 先保存到本地
      await _localStorageService.saveProgress(progress);
      print('✅ 已保存到本地存储');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 同步到远程数据库
          final remoteProgress = await _supabaseService.createUserProgress(
            userId: userId,
            sessionId: sessionId,
            totalLessons: totalLessons,
          );
          
          // 更新本地存储的ID
          await _localStorageService.saveProgress(remoteProgress);
          print('✅ 已同步到远程数据库');
          return remoteProgress;
        } catch (error) {
          print('⚠️ 同步到远程失败: $error，但本地创建成功');
        }
      }
      
      return progress;
    } catch (error) {
      print('❌ 创建学习进度失败: $error');
      rethrow;
    }
  }

  @override
  Future<ProgressEntity> updateProgress({
    String? userId,
    String? sessionId,
    required int lessonIndex,
    required int lessonNumber,
    int? totalLessons,
  }) async {
    try {
      print('💾 更新学习进度: 第${lessonNumber}课 (索引${lessonIndex})');
      
      // 先从本地获取当前进度
      final currentProgress = await _localStorageService.loadProgress();
      
      ProgressEntity updatedProgress;
      
      if (currentProgress != null) {
        // 更新现有进度
        updatedProgress = currentProgress.updateProgress(
          lessonIndex: lessonIndex,
          lessonNumber: lessonNumber,
          totalLessons: totalLessons,
        );
      } else {
        // 创建新进度
        updatedProgress = ProgressEntity.create(
          id: _uuid.v4(),
          userId: userId,
          sessionId: sessionId,
          currentLessonIndex: lessonIndex,
          currentLessonNumber: lessonNumber,
          totalLessons: totalLessons ?? 1,
        );
      }
      
      // 保存到本地
      await _localStorageService.saveProgress(updatedProgress);
      print('✅ 已更新本地进度');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 同步到远程数据库
          final remoteProgress = await _supabaseService.updateUserProgress(
            userId: userId,
            sessionId: sessionId,
            lessonIndex: lessonIndex,
            lessonNumber: lessonNumber,
            totalLessons: totalLessons,
          );
          
          // 更新本地存储
          await _localStorageService.saveProgress(remoteProgress);
          print('✅ 已同步到远程数据库');
          return remoteProgress;
        } catch (error) {
          print('⚠️ 同步到远程失败: $error，但本地更新成功');
        }
      }
      
      return updatedProgress;
    } catch (error) {
      print('❌ 更新学习进度失败: $error');
      rethrow;
    }
  }

  @override
  Future<bool> clearProgress({
    String? userId,
    String? sessionId,
  }) async {
    try {
      print('🗑️ 清除学习进度...');
      
      // 清除本地进度
      await _localStorageService.clearProgress();
      print('✅ 已清除本地进度');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 清除远程进度
          await _supabaseService.clearUserProgress(
            userId: userId,
            sessionId: sessionId,
          );
          print('✅ 已清除远程进度');
        } catch (error) {
          print('⚠️ 清除远程进度失败: $error，但本地清除成功');
        }
      }
      
      return true;
    } catch (error) {
      print('❌ 清除学习进度失败: $error');
      return false;
    }
  }

  @override
  Future<ProgressEntity> getOrCreateProgress({
    String? userId,
    String? sessionId,
    required int totalLessons,
  }) async {
    try {
      // 先尝试获取现有进度
      final existingProgress = await getProgress(
        userId: userId,
        sessionId: sessionId,
      );
      
      if (existingProgress != null) {
        print('✅ 找到现有学习进度');
        
        // 如果总课程数发生变化，更新进度
        if (existingProgress.totalLessons != totalLessons) {
          print('🔄 总课程数发生变化，更新进度');
          return await updateProgress(
            userId: userId,
            sessionId: sessionId,
            lessonIndex: existingProgress.currentLessonIndex,
            lessonNumber: existingProgress.currentLessonNumber,
            totalLessons: totalLessons,
          );
        }
        
        return existingProgress;
      }
      
      // 创建新进度
      print('📝 创建新的学习进度');
      return await createProgress(
        userId: userId,
        sessionId: sessionId,
        totalLessons: totalLessons,
      );
    } catch (error) {
      print('❌ 获取或创建学习进度失败: $error');
      rethrow;
    }
  }

  @override
  Future<bool> syncProgressToRemote(ProgressEntity progress) async {
    try {
      print('🔄 同步进度到远程数据库...');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (!isOnline) {
        print('⚠️ 网络不可用，无法同步');
        return false;
      }
      
      await _supabaseService.updateUserProgress(
        userId: progress.userId,
        sessionId: progress.sessionId,
        lessonIndex: progress.currentLessonIndex,
        lessonNumber: progress.currentLessonNumber,
        totalLessons: progress.totalLessons,
      );
      
      print('✅ 进度同步成功');
      return true;
    } catch (error) {
      print('❌ 同步进度失败: $error');
      return false;
    }
  }

  @override
  Future<ProgressEntity?> syncProgressFromRemote({
    String? userId,
    String? sessionId,
  }) async {
    try {
      print('🔄 从远程同步进度...');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (!isOnline) {
        print('⚠️ 网络不可用，无法同步');
        return null;
      }
      
      final remoteProgress = await _supabaseService.getUserProgress(
        userId: userId,
        sessionId: sessionId,
      );
      
      if (remoteProgress != null) {
        // 更新本地存储
        await _localStorageService.saveProgress(remoteProgress);
        print('✅ 从远程同步进度成功');
        return remoteProgress;
      } else {
        print('ℹ️ 远程没有找到进度记录');
        return null;
      }
    } catch (error) {
      print('❌ 从远程同步进度失败: $error');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getProgressStats({
    String? userId,
    String? sessionId,
  }) async {
    try {
      final progress = await getProgress(
        userId: userId,
        sessionId: sessionId,
      );
      
      if (progress == null) {
        return {
          'has_progress': false,
          'current_lesson': 0,
          'total_lessons': 0,
          'progress_percentage': 0.0,
          'remaining_lessons': 0,
          'is_completed': false,
        };
      }
      
      return {
        'has_progress': true,
        'current_lesson': progress.currentLessonNumber,
        'current_lesson_index': progress.currentLessonIndex,
        'total_lessons': progress.totalLessons,
        'progress_percentage': progress.progressPercentage,
        'remaining_lessons': progress.remainingLessons,
        'is_completed': progress.isCompleted,
        'last_accessed': progress.lastAccessedAt.toIso8601String(),
        'created_at': progress.createdAt.toIso8601String(),
        'updated_at': progress.updatedAt.toIso8601String(),
      };
    } catch (error) {
      print('❌ 获取进度统计失败: $error');
      return {
        'has_progress': false,
        'error': error.toString(),
      };
    }
  }
}
