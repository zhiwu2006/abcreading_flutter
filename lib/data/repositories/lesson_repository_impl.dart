import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/database/supabase_service.dart';
import '../../services/storage/local_storage_service.dart';

/// 课程仓库实现类
class LessonRepositoryImpl implements LessonRepository {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final Connectivity _connectivity;

  LessonRepositoryImpl({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    required Connectivity connectivity,
  }) : _supabaseService = supabaseService,
       _localStorageService = localStorageService,
       _connectivity = connectivity;

  @override
  Future<List<LessonEntity>> getLessons() async {
    try {
      print('📚 开始获取课程数据...');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      print('🌐 网络状态: ${isOnline ? '在线' : '离线'}');
      
      if (isOnline) {
        // 在线时优先从数据库获取
        try {
          final remoteLessons = await _supabaseService.getLessons();
          
          if (remoteLessons.isNotEmpty) {
            print('✅ 从数据库获取到 ${remoteLessons.length} 个课程');
            
            // 缓存到本地
            await _localStorageService.saveLessons(remoteLessons);
            return remoteLessons;
          } else {
            print('ℹ️ 数据库中暂无课程，尝试从本地获取');
          }
        } catch (error) {
          print('⚠️ 从数据库获取课程失败: $error，尝试从本地获取');
        }
      }
      
      // 从本地存储获取
      final localLessons = await _localStorageService.loadLessons();
      
      if (localLessons.isNotEmpty) {
        print('✅ 从本地存储获取到 ${localLessons.length} 个课程');
        return localLessons;
      }
      
      // 如果本地也没有，加载默认课程
      print('ℹ️ 本地存储中也没有课程，加载默认课程');
      return await _loadDefaultLessons();
      
    } catch (error) {
      print('❌ 获取课程数据失败: $error');
      
      // 最后尝试加载默认课程
      try {
        return await _loadDefaultLessons();
      } catch (defaultError) {
        print('❌ 加载默认课程也失败: $defaultError');
        rethrow;
      }
    }
  }

  @override
  Future<bool> saveLessons(List<LessonEntity> lessons) async {
    if (lessons.isEmpty) {
      print('⚠️ 没有课程需要保存');
      return false;
    }

    try {
      print('💾 开始保存 ${lessons.length} 个课程...');
      
      // 先保存到本地存储
      await _localStorageService.saveLessons(lessons);
      print('✅ 已保存到本地存储');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 同步到数据库
          final success = await _supabaseService.saveLessons(lessons);
          if (success) {
            print('✅ 已同步到数据库');
          } else {
            print('⚠️ 同步到数据库失败，但本地保存成功');
          }
          return true;
        } catch (error) {
          print('⚠️ 同步到数据库失败: $error，但本地保存成功');
          return true; // 本地保存成功就算成功
        }
      } else {
        print('ℹ️ 离线状态，仅保存到本地存储');
        return true;
      }
    } catch (error) {
      print('❌ 保存课程失败: $error');
      return false;
    }
  }

  @override
  Future<bool> deleteLessons(List<int> lessonNumbers) async {
    if (lessonNumbers.isEmpty) {
      print('⚠️ 没有课程需要删除');
      return false;
    }

    try {
      print('🗑️ 开始删除课程: $lessonNumbers');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // 从数据库删除
          await _supabaseService.deleteLessons(lessonNumbers);
          print('✅ 已从数据库删除');
        } catch (error) {
          print('⚠️ 从数据库删除失败: $error');
        }
      }
      
      // 从本地存储删除
      final localLessons = await _localStorageService.loadLessons();
      final filteredLessons = localLessons
          .where((lesson) => !lessonNumbers.contains(lesson.lesson))
          .toList();
      
      await _localStorageService.saveLessons(filteredLessons);
      print('✅ 已从本地存储删除');
      
      return true;
    } catch (error) {
      print('❌ 删除课程失败: $error');
      return false;
    }
  }

  @override
  Future<List<LessonEntity>> searchLessons(String query) async {
    try {
      final lessons = await getLessons();
      
      if (query.isEmpty) {
        return lessons;
      }
      
      final lowercaseQuery = query.toLowerCase();
      
      return lessons.where((lesson) {
        return lesson.title.toLowerCase().contains(lowercaseQuery) ||
               lesson.content.toLowerCase().contains(lowercaseQuery) ||
               lesson.lesson.toString().contains(query);
      }).toList();
    } catch (error) {
      print('❌ 搜索课程失败: $error');
      return [];
    }
  }

  @override
  Future<LessonEntity?> getLessonById(int lessonNumber) async {
    try {
      final lessons = await getLessons();
      
      for (final lesson in lessons) {
        if (lesson.lesson == lessonNumber) {
          return lesson;
        }
      }
      
      return null;
    } catch (error) {
      print('❌ 获取课程失败: $error');
      return null;
    }
  }

  @override
  Future<List<LessonEntity>> getLessonsByRange(int start, int end) async {
    try {
      final lessons = await getLessons();
      
      return lessons.where((lesson) {
        return lesson.lesson >= start && lesson.lesson <= end;
      }).toList();
    } catch (error) {
      print('❌ 获取课程范围失败: $error');
      return [];
    }
  }

  @override
  Future<bool> syncWithRemote() async {
    try {
      print('🔄 开始与远程数据库同步...');
      
      // 检查网络连接
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (!isOnline) {
        print('⚠️ 网络不可用，无法同步');
        return false;
      }
      
      // 获取远程课程
      final remoteLessons = await _supabaseService.getLessons();
      
      if (remoteLessons.isNotEmpty) {
        // 更新本地缓存
        await _localStorageService.saveLessons(remoteLessons);
        print('✅ 同步完成，更新了 ${remoteLessons.length} 个课程');
        return true;
      } else {
        print('ℹ️ 远程数据库中没有课程数据');
        return false;
      }
    } catch (error) {
      print('❌ 同步失败: $error');
      return false;
    }
  }

  @override
  Future<bool> clearCache() async {
    try {
      await _localStorageService.clearLessonsCache();
      print('✅ 已清除课程缓存');
      return true;
    } catch (error) {
      print('❌ 清除缓存失败: $error');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      return _localStorageService.getCacheStats();
    } catch (error) {
      print('❌ 获取缓存信息失败: $error');
      return {};
    }
  }

  @override
  Future<bool> importLessonsFromJson(String jsonString) async {
    try {
      print('📥 开始导入JSON课程数据...');
      
      final jsonData = jsonDecode(jsonString);
      final List<LessonEntity> lessons = [];
      
      if (jsonData is List) {
        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            try {
              final lesson = LessonEntity.fromJson(item);
              lessons.add(lesson);
            } catch (error) {
              print('⚠️ 解析课程数据失败: $error');
            }
          }
        }
      } else {
        throw Exception('JSON数据格式不正确，应该是数组格式');
      }
      
      if (lessons.isEmpty) {
        throw Exception('没有有效的课程数据');
      }
      
      // 检查重复课程
      final existingLessons = await getLessons();
      final existingNumbers = existingLessons.map((l) => l.lesson).toSet();
      
      final newLessons = lessons.where((lesson) {
        return !existingNumbers.contains(lesson.lesson);
      }).toList();
      
      if (newLessons.isEmpty) {
        print('ℹ️ 所有课程都已存在，没有新课程需要导入');
        return false;
      }
      
      // 合并课程
      final allLessons = [...existingLessons, ...newLessons];
      allLessons.sort((a, b) => a.lesson.compareTo(b.lesson));
      
      // 保存合并后的课程
      final success = await saveLessons(allLessons);
      
      if (success) {
        print('✅ 成功导入 ${newLessons.length} 个新课程');
        return true;
      } else {
        throw Exception('保存导入的课程失败');
      }
    } catch (error) {
      print('❌ 导入课程失败: $error');
      return false;
    }
  }

  /// 加载默认课程数据
  Future<List<LessonEntity>> _loadDefaultLessons() async {
    try {
      print('📖 加载默认课程数据...');
      
      final jsonString = await rootBundle.loadString('assets/data/default_lessons.json');
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      
      final lessons = jsonData
          .map((json) => LessonEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ 成功加载 ${lessons.length} 个默认课程');
      
      // 缓存到本地存储
      await _localStorageService.saveLessons(lessons);
      
      return lessons;
    } catch (error) {
      print('❌ 加载默认课程失败: $error');
      rethrow;
    }
  }

  /// 检查网络连接状态
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (error) {
      print('❌ 检查网络状态失败: $error');
      return false;
    }
  }

  /// 获取数据源信息
  Future<Map<String, dynamic>> getDataSourceInfo() async {
    try {
      final isOnline = await this.isOnline();
      final cacheInfo = await getCacheInfo();
      
      return {
        'is_online': isOnline,
        'cache_info': cacheInfo,
        'data_source': isOnline ? 'remote' : 'local',
      };
    } catch (error) {
      print('❌ 获取数据源信息失败: $error');
      return {};
    }
  }
}