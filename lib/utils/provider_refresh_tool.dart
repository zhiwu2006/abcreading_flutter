import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/lesson_provider.dart';
import '../presentation/providers/progress_provider.dart';
import '../services/storage/local_storage_service.dart';

class ProviderRefreshTool {
  /// 强制刷新所有Provider
  static Future<Map<String, dynamic>> forceRefreshAllProviders(BuildContext context) async {
    final result = <String, dynamic>{
      'success': false,
      'refreshed_providers': <String>[],
      'errors': <String>[],
    };

    try {
      print('🔄 开始强制刷新所有Provider...');

      // 1. 刷新LessonProvider
      try {
        final lessonProvider = context.read<LessonProvider>();
        print('📚 刷新LessonProvider...');
        await lessonProvider.loadLessons();
        result['refreshed_providers'].add('LessonProvider');
        print('✅ LessonProvider刷新完成，课程数量: ${lessonProvider.totalLessons}');
      } catch (e) {
        final error = 'LessonProvider刷新失败: $e';
        result['errors'].add(error);
        print('❌ $error');
      }

      // 2. 刷新ProgressProvider
      try {
        final progressProvider = context.read<ProgressProvider>();
        print('📊 刷新ProgressProvider...');
        await progressProvider.refresh();
        result['refreshed_providers'].add('ProgressProvider');
        print('✅ ProgressProvider刷新完成');
      } catch (e) {
        final error = 'ProgressProvider刷新失败: $e';
        result['errors'].add(error);
        print('❌ $error');
      }

      // 3. 强制刷新LocalStorageService
      try {
        final localStorage = LocalStorageService.instance;
        print('💾 检查LocalStorageService缓存状态...');
        final cacheStats = localStorage.getCacheStats();
        print('📊 缓存统计: $cacheStats');
        result['cache_stats'] = cacheStats;
      } catch (e) {
        final error = 'LocalStorageService检查失败: $e';
        result['errors'].add(error);
        print('❌ $error');
      }

      result['success'] = result['errors'].isEmpty;
      
      if (result['success']) {
        print('✅ 所有Provider刷新完成');
      } else {
        print('⚠️ Provider刷新完成，但有部分错误');
      }

    } catch (e) {
      result['errors'].add('刷新过程中发生未知错误: $e');
      print('❌ 刷新过程中发生未知错误: $e');
    }

    return result;
  }

  /// 检查Provider状态
  static Map<String, dynamic> checkProviderStatus(BuildContext context) {
    final status = <String, dynamic>{};

    try {
      // 检查LessonProvider状态
      final lessonProvider = context.read<LessonProvider>();
      status['lesson_provider'] = {
        'total_lessons': lessonProvider.totalLessons,
        'filtered_lessons': lessonProvider.filteredLessons.length,
        'current_lesson': lessonProvider.currentLesson?.lesson,
        'is_loading': lessonProvider.isLoading,
        'is_syncing': lessonProvider.isSyncing,
        'has_error': lessonProvider.hasError,
        'error': lessonProvider.error,
      };

      // 检查ProgressProvider状态
      final progressProvider = context.read<ProgressProvider>();
      status['progress_provider'] = {
        'current_lesson_number': progressProvider.currentLessonNumber,
        'completed_lessons': 0, // 临时修复，需要检查ProgressProvider的实际属性
        'total_lessons': progressProvider.totalLessons,
        'progress_percentage': progressProvider.progressPercentage,
        'has_progress': progressProvider.hasProgress,
        'is_completed': progressProvider.isCompleted,
      };

      // 检查LocalStorageService状态
      final localStorage = LocalStorageService.instance;
      status['local_storage'] = localStorage.getCacheStats();

    } catch (e) {
      status['error'] = '检查Provider状态失败: $e';
    }

    return status;
  }

  /// 显示Provider状态对话框
  static void showProviderStatusDialog(BuildContext context) {
    final status = checkProviderStatus(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider状态'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusSection('课程Provider', status['lesson_provider']),
              const SizedBox(height: 16),
              _buildStatusSection('进度Provider', status['progress_provider']),
              const SizedBox(height: 16),
              _buildStatusSection('本地存储', status['local_storage']),
              if (status['error'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  '错误: ${status['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showRefreshDialog(context);
            },
            child: const Text('刷新所有'),
          ),
        ],
      ),
    );
  }

  /// 构建状态区域
  static Widget _buildStatusSection(String title, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (data is Map<String, dynamic>) ...[
          ...data.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              data?.toString() ?? '无数据',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// 显示刷新对话框
  static Future<void> _showRefreshDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在刷新Provider...'),
          ],
        ),
      ),
    );

    try {
      final result = await forceRefreshAllProviders(context);
      
      Navigator.pop(context); // 关闭加载对话框

      // 显示结果
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['success'] ? '刷新成功' : '刷新完成'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result['refreshed_providers'].isNotEmpty) ...[
                const Text('已刷新的Provider:'),
                ...result['refreshed_providers'].map<Widget>((provider) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text('✅ $provider'),
                  ),
                ),
              ],
              if (result['errors'].isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('错误信息:'),
                ...result['errors'].map<Widget>((error) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '❌ $error',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              ],
              if (result['cache_stats'] != null) ...[
                const SizedBox(height: 8),
                const Text('缓存统计:'),
                Text(
                  '课程数量: ${result['cache_stats']['lessons_count'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context); // 关闭加载对话框
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('刷新失败'),
          content: Text('刷新过程中发生错误: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  /// 打印详细的Provider状态
  static void printProviderStatus(BuildContext context) {
    print('🔍 ===== Provider状态详情 =====');
    
    final status = checkProviderStatus(context);
    
    print('📚 LessonProvider状态:');
    final lessonStatus = status['lesson_provider'] as Map<String, dynamic>?;
    if (lessonStatus != null) {
      lessonStatus.forEach((key, value) {
        print('  - $key: $value');
      });
    }
    
    print('📊 ProgressProvider状态:');
    final progressStatus = status['progress_provider'] as Map<String, dynamic>?;
    if (progressStatus != null) {
      progressStatus.forEach((key, value) {
        print('  - $key: $value');
      });
    }
    
    print('💾 LocalStorageService状态:');
    final storageStatus = status['local_storage'] as Map<String, dynamic>?;
    if (storageStatus != null) {
      storageStatus.forEach((key, value) {
        print('  - $key: $value');
      });
    }
    
    if (status['error'] != null) {
      print('❌ 错误: ${status['error']}');
    }
    
    print('🔍 ===== Provider状态详情结束 =====');
  }
}