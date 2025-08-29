import 'dart:convert';
import '../entities/lesson_entity.dart';
import '../repositories/lesson_repository.dart';

/// 获取课程列表用例
class GetLessonsUseCase {
  final LessonRepository _repository;

  GetLessonsUseCase(this._repository);

  Future<List<LessonEntity>> call() async {
    return await _repository.getLessons();
  }
}

/// 保存课程用例
class SaveLessonsUseCase {
  final LessonRepository _repository;

  SaveLessonsUseCase(this._repository);

  Future<bool> call(List<LessonEntity> lessons) async {
    return await _repository.saveLessons(lessons);
  }
}

/// 删除课程用例
class DeleteLessonsUseCase {
  final LessonRepository _repository;

  DeleteLessonsUseCase(this._repository);

  Future<bool> call(List<int> lessonNumbers) async {
    return await _repository.deleteLessons(lessonNumbers);
  }
}

/// 搜索课程用例
class SearchLessonsUseCase {
  final LessonRepository _repository;

  SearchLessonsUseCase(this._repository);

  Future<List<LessonEntity>> call(String query) async {
    return await _repository.searchLessons(query);
  }
}

/// 获取单个课程用例
class GetLessonByIdUseCase {
  final LessonRepository _repository;

  GetLessonByIdUseCase(this._repository);

  Future<LessonEntity?> call(int lessonNumber) async {
    return await _repository.getLessonById(lessonNumber);
  }
}

/// 获取课程范围用例
class GetLessonsByRangeUseCase {
  final LessonRepository _repository;

  GetLessonsByRangeUseCase(this._repository);

  Future<List<LessonEntity>> call(int start, int end) async {
    return await _repository.getLessonsByRange(start, end);
  }
}

/// 同步课程用例
class SyncLessonsUseCase {
  final LessonRepository _repository;

  SyncLessonsUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.syncWithRemote();
  }
}

/// 清除课程缓存用例
class ClearLessonsCacheUseCase {
  final LessonRepository _repository;

  ClearLessonsCacheUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.clearCache();
  }
}

/// 获取缓存信息用例
class GetCacheInfoUseCase {
  final LessonRepository _repository;

  GetCacheInfoUseCase(this._repository);

  Future<Map<String, dynamic>> call() async {
    return await _repository.getCacheInfo();
  }
}

/// 导入课程用例
class ImportLessonsUseCase {
  final LessonRepository _repository;

  ImportLessonsUseCase(this._repository);

  Future<bool> call(String jsonString) async {
    return await _repository.importLessonsFromJson(jsonString);
  }
}

/// 检查重复课程用例
class CheckDuplicateLessonsUseCase {
  final LessonRepository _repository;

  CheckDuplicateLessonsUseCase(this._repository);

  Future<List<LessonEntity>> call(List<LessonEntity> newLessons) async {
    try {
      // 获取现有课程
      final existingLessons = await _repository.getLessons();
      final existingKeys = existingLessons
          .map((lesson) => '${lesson.lesson}-${lesson.title}')
          .toSet();
      
      // 过滤重复课程
      final uniqueLessons = newLessons.where((lesson) {
        final key = '${lesson.lesson}-${lesson.title}';
        return !existingKeys.contains(key);
      }).toList();
      
      return uniqueLessons;
    } catch (error) {
      print('❌ 检查重复课程失败: $error');
      return [];
    }
  }
}

/// 批量管理课程用例
class BatchManageLessonsUseCase {
  final LessonRepository _repository;

  BatchManageLessonsUseCase(this._repository);

  /// 批量导入课程
  Future<Map<String, dynamic>> importBatch(List<LessonEntity> lessons) async {
    try {
      print('📥 开始批量导入 ${lessons.length} 个课程...');
      
      // 检查重复课程
      final checkDuplicateUseCase = CheckDuplicateLessonsUseCase(_repository);
      final uniqueLessons = await checkDuplicateUseCase(lessons);
      
      final duplicateCount = lessons.length - uniqueLessons.length;
      
      if (uniqueLessons.isEmpty) {
        return {
          'success': false,
          'message': '所有课程都已存在，没有新课程需要导入',
          'imported_count': 0,
          'duplicate_count': duplicateCount,
          'total_count': lessons.length,
        };
      }
      
      // 获取现有课程并合并
      final existingLessons = await _repository.getLessons();
      final allLessons = [...existingLessons, ...uniqueLessons];
      allLessons.sort((a, b) => a.lesson.compareTo(b.lesson));
      
      // 保存合并后的课程
      final success = await _repository.saveLessons(allLessons);
      
      if (success) {
        return {
          'success': true,
          'message': duplicateCount > 0 
              ? '成功导入 ${uniqueLessons.length} 个新课程，跳过 $duplicateCount 个重复课程'
              : '成功导入 ${uniqueLessons.length} 个课程',
          'imported_count': uniqueLessons.length,
          'duplicate_count': duplicateCount,
          'total_count': lessons.length,
        };
      } else {
        throw Exception('保存课程失败');
      }
    } catch (error) {
      print('❌ 批量导入课程失败: $error');
      return {
        'success': false,
        'message': '批量导入失败: $error',
        'imported_count': 0,
        'duplicate_count': 0,
        'total_count': lessons.length,
      };
    }
  }

  /// 批量删除课程
  Future<Map<String, dynamic>> deleteBatch(List<int> lessonNumbers) async {
    try {
      print('🗑️ 开始批量删除 ${lessonNumbers.length} 个课程...');
      
      final success = await _repository.deleteLessons(lessonNumbers);
      
      if (success) {
        return {
          'success': true,
          'message': '成功删除 ${lessonNumbers.length} 个课程',
          'deleted_count': lessonNumbers.length,
        };
      } else {
        throw Exception('删除课程失败');
      }
    } catch (error) {
      print('❌ 批量删除课程失败: $error');
      return {
        'success': false,
        'message': '批量删除失败: $error',
        'deleted_count': 0,
      };
    }
  }

  /// 批量更新课程
  Future<Map<String, dynamic>> updateBatch(List<LessonEntity> lessons) async {
    try {
      print('🔄 开始批量更新 ${lessons.length} 个课程...');
      
      // 获取现有课程
      final existingLessons = await _repository.getLessons();
      final existingMap = {
        for (var lesson in existingLessons) lesson.lesson: lesson
      };
      
      // 更新课程
      final updatedLessons = <LessonEntity>[];
      int updatedCount = 0;
      int newCount = 0;
      
      for (final lesson in lessons) {
        if (existingMap.containsKey(lesson.lesson)) {
          // 更新现有课程
          updatedLessons.add(lesson.copyWith(
            createdAt: existingMap[lesson.lesson]!.createdAt,
            updatedAt: DateTime.now(),
          ));
          updatedCount++;
        } else {
          // 新增课程
          updatedLessons.add(lesson.copyWith(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          newCount++;
        }
      }
      
      // 保留未更新的现有课程
      for (final existingLesson in existingLessons) {
        if (!lessons.any((l) => l.lesson == existingLesson.lesson)) {
          updatedLessons.add(existingLesson);
        }
      }
      
      // 排序并保存
      updatedLessons.sort((a, b) => a.lesson.compareTo(b.lesson));
      final success = await _repository.saveLessons(updatedLessons);
      
      if (success) {
        return {
          'success': true,
          'message': '成功更新 $updatedCount 个课程，新增 $newCount 个课程',
          'updated_count': updatedCount,
          'new_count': newCount,
          'total_count': lessons.length,
        };
      } else {
        throw Exception('保存课程失败');
      }
    } catch (error) {
      print('❌ 批量更新课程失败: $error');
      return {
        'success': false,
        'message': '批量更新失败: $error',
        'updated_count': 0,
        'new_count': 0,
        'total_count': lessons.length,
      };
    }
  }

  /// 导出课程为JSON
  Future<String> exportToJson(List<int>? lessonNumbers) async {
    try {
      List<LessonEntity> lessonsToExport;
      
      if (lessonNumbers != null && lessonNumbers.isNotEmpty) {
        // 导出指定课程
        lessonsToExport = [];
        for (final number in lessonNumbers) {
          final lesson = await _repository.getLessonById(number);
          if (lesson != null) {
            lessonsToExport.add(lesson);
          }
        }
      } else {
        // 导出所有课程
        lessonsToExport = await _repository.getLessons();
      }
      
      if (lessonsToExport.isEmpty) {
        throw Exception('没有课程可以导出');
      }
      
      // 转换为JSON
      final jsonList = lessonsToExport.map((lesson) => lesson.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      print('✅ 成功导出 ${lessonsToExport.length} 个课程');
      return jsonString;
    } catch (error) {
      print('❌ 导出课程失败: $error');
      rethrow;
    }
  }
}