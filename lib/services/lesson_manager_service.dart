import '../models/lesson.dart';
import '../data/default_lessons.dart';
import 'supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum LessonSource {
  local,    // 本地数据
  remote,   // 远程数据
  mixed,    // 混合模式（优先远程，回退本地）
}

class LessonManagerService {
  static final LessonManagerService _instance = LessonManagerService._internal();
  factory LessonManagerService() => _instance;
  LessonManagerService._internal();

  static LessonManagerService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService.instance;
  LessonSource _currentSource = LessonSource.mixed;
  List<Lesson>? _cachedRemoteLessons;
  List<Lesson>? _cachedLocalLessons;

  /// 获取当前数据源
  LessonSource get currentSource => _currentSource;

  /// 设置数据源
  void setSource(LessonSource source) {
    _currentSource = source;
    _clearCache();
  }

  /// 清除缓存
  void _clearCache() {
    _cachedRemoteLessons = null;
    _cachedLocalLessons = null;
  }

  /// 获取课程列表
  Future<List<Lesson>> getLessons() async {
    switch (_currentSource) {
      case LessonSource.local:
        return await getLocalLessons();
      case LessonSource.remote:
        return await getRemoteLessons();
      case LessonSource.mixed:
        return await getMixedLessons();
    }
  }

  /// 获取本地课程
  Future<List<Lesson>> getLocalLessons() async {
    if (_cachedLocalLessons != null) {
      print('📋 使用内存缓存的本地课程，共 ${_cachedLocalLessons!.length} 个');
      return _cachedLocalLessons!;
    }

    try {
      // 首先尝试从本地存储加载缓存的课程
      final prefs = await SharedPreferences.getInstance();
      final cachedLessonsJson = prefs.getString('cached_lessons');
      
      if (cachedLessonsJson != null && cachedLessonsJson.isNotEmpty) {
        final List<dynamic> lessonsList = json.decode(cachedLessonsJson);
        _cachedLocalLessons = lessonsList.map((json) => Lesson.fromJson(json)).toList();
        print('✅ 从本地缓存加载了 ${_cachedLocalLessons!.length} 个课程');
        
        // 验证缓存数据的有效性
        if (_cachedLocalLessons!.isNotEmpty) {
          print('📊 缓存课程示例: ${_cachedLocalLessons!.first.title}');
          return _cachedLocalLessons!;
        }
      }
    } catch (e) {
      print('⚠️ 加载本地缓存课程失败: $e');
    }

    // 如果没有有效缓存，使用默认课程
    _cachedLocalLessons = List.from(defaultLessons);
    print('⚠️ 没有找到有效的本地缓存，使用默认课程数据，共 ${_cachedLocalLessons!.length} 个课程');
    return _cachedLocalLessons!;
  }

  /// 获取远程课程
  Future<List<Lesson>> getRemoteLessons() async {
    if (_cachedRemoteLessons != null) {
      return _cachedRemoteLessons!;
    }

    if (!_supabaseService.isInitialized) {
      throw Exception('Supabase 未初始化，无法获取远程课程');
    }

    try {
      final response = await _supabaseService.client
          .from('lessons')
          .select()
          .order('lesson_number');

      if (response.isEmpty) {
        print('⚠️ 远程数据库中没有课程数据');
        return [];
      }

      _cachedRemoteLessons = response.map<Lesson>((json) => Lesson.fromSupabaseJson(json)).toList();
      print('✅ 从远程加载了 ${_cachedRemoteLessons!.length} 个课程');
      return _cachedRemoteLessons!;
    } catch (e) {
      print('❌ 获取远程课程失败: $e');
      throw Exception('获取远程课程失败: $e');
    }
  }

  /// 获取混合模式课程（优先远程，回退本地）
  Future<List<Lesson>> getMixedLessons() async {
    try {
      // 首先尝试获取远程课程
      final remoteLessons = await getRemoteLessons();
      if (remoteLessons.isNotEmpty) {
        print('✅ 混合模式：使用远程课程数据');
        return remoteLessons;
      }
    } catch (e) {
      print('⚠️ 混合模式：远程课程获取失败，回退到本地数据: $e');
    }

    // 远程获取失败，使用本地课程
    final localLessons = await getLocalLessons();
    print('✅ 混合模式：使用本地课程数据');
    return localLessons;
  }

  /// 将远程课程同步到本地
  Future<bool> syncRemoteToLocal() async {
    try {
      print('🔄 开始同步远程课程到本地...');
      
      // 清除远程缓存以获取最新数据
      _cachedRemoteLessons = null;
      
      final remoteLessons = await getRemoteLessons();
      if (remoteLessons.isEmpty) {
        print('⚠️ 远程没有课程数据可同步');
        return false;
      }

      // 保存到本地缓存
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = json.encode(remoteLessons.map((lesson) => lesson.toJson()).toList());
      await prefs.setString('cached_lessons', lessonsJson);
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      // 立即更新内存缓存
      _cachedLocalLessons = List.from(remoteLessons);
      
      print('✅ 成功同步 ${remoteLessons.length} 个课程到本地');
      print('📝 本地缓存已更新');
      print('🔍 内存缓存课程示例: ${_cachedLocalLessons!.isNotEmpty ? _cachedLocalLessons!.first.title : "无"}');
      return true;
    } catch (e) {
      print('❌ 同步远程课程到本地失败: $e');
      return false;
    }
  }

  /// 将本地课程上传到远程
  Future<bool> uploadLocalToRemote() async {
    if (!_supabaseService.isInitialized) {
      print('❌ Supabase 未初始化，无法上传课程');
      return false;
    }

    try {
      print('🔄 开始上传本地课程到远程...');
      
      final localLessons = await getLocalLessons();
      if (localLessons.isEmpty) {
        print('⚠️ 本地没有课程数据可上传');
        return false;
      }

      // 转换为数据库格式
      final lessonsData = localLessons.map((lesson) => lesson.toSupabaseJson()).toList();

      // 先清空远程数据，然后插入新数据
      await _supabaseService.client.from('lessons').delete().neq('id', 0);
      await _supabaseService.client.from('lessons').insert(lessonsData);

      // 清除远程缓存以便重新加载
      _cachedRemoteLessons = null;
      
      print('✅ 成功上传 ${localLessons.length} 个课程到远程');
      return true;
    } catch (e) {
      print('❌ 上传本地课程到远程失败: $e');
      return false;
    }
  }

  /// 刷新所有缓存
  Future<void> refreshAll() async {
    print('🔄 刷新所有课程缓存...');
    
    // 只清除内存缓存，保留本地存储的同步数据
    _cachedLocalLessons = null;
    _cachedRemoteLessons = null;
    
    // 预加载数据
    try {
      await getLocalLessons();
      if (_supabaseService.isInitialized) {
        await getRemoteLessons();
      }
    } catch (e) {
      print('⚠️ 刷新缓存时出现错误: $e');
    }
    
    print('✅ 课程缓存刷新完成');
  }

  /// 强制重新加载本地缓存数据
  Future<void> forceReloadLocalCache() async {
    print('🔄 强制重新加载本地缓存数据...');
    
    // 清除内存缓存
    _cachedLocalLessons = null;
    
    try {
      // 重新从 SharedPreferences 加载
      final prefs = await SharedPreferences.getInstance();
      final cachedLessonsJson = prefs.getString('cached_lessons');
      
      if (cachedLessonsJson != null && cachedLessonsJson.isNotEmpty) {
        final List<dynamic> lessonsList = json.decode(cachedLessonsJson);
        _cachedLocalLessons = lessonsList.map((json) => Lesson.fromJson(json)).toList();
        print('✅ 强制重新加载了 ${_cachedLocalLessons!.length} 个缓存课程');
        
        // 打印前几个课程的标题以验证数据
        if (_cachedLocalLessons!.isNotEmpty) {
          final firstFew = _cachedLocalLessons!.take(3).map((l) => l.title).join(', ');
          print('📋 缓存课程示例: $firstFew');
        }
      } else {
        print('⚠️ SharedPreferences 中没有找到缓存数据');
      }
    } catch (e) {
      print('❌ 强制重新加载缓存失败: $e');
    }
  }

  /// 删除单个课程
  Future<bool> deleteLesson(int lessonNumber) async {
    try {
      print('🗑️ 开始删除课程 $lessonNumber...');
      
      // 从内存缓存中删除
      if (_cachedLocalLessons != null) {
        _cachedLocalLessons!.removeWhere((lesson) => lesson.lesson == lessonNumber);
      }
      
      // 从本地存储中删除
      await _updateLocalCache();
      
      print('✅ 课程 $lessonNumber 删除完成');
      return true;
    } catch (e) {
      print('❌ 删除课程 $lessonNumber 失败: $e');
      return false;
    }
  }

  /// 批量删除课程
  Future<bool> deleteLessons(List<int> lessonNumbers) async {
    try {
      print('🗑️ 开始批量删除 ${lessonNumbers.length} 个课程...');
      
      // 从内存缓存中删除
      if (_cachedLocalLessons != null) {
        _cachedLocalLessons!.removeWhere((lesson) => lessonNumbers.contains(lesson.lesson));
      }
      
      // 更新本地存储
      await _updateLocalCache();
      
      print('✅ 批量删除 ${lessonNumbers.length} 个课程完成');
      return true;
    } catch (e) {
      print('❌ 批量删除课程失败: $e');
      return false;
    }
  }

  /// 添加新课程
  Future<bool> addLessons(List<Lesson> newLessons) async {
    try {
      print('➕ 开始添加 ${newLessons.length} 个课程...');
      
      // 检查重复课程
      final localLessons = await getLocalLessons();
      final existingLessonNumbers = localLessons.map((l) => l.lesson).toSet();
      final lessonsToAdd = newLessons.where((lesson) => !existingLessonNumbers.contains(lesson.lesson)).toList();
      
      if (lessonsToAdd.isEmpty) {
        print('⚠️ 所有课程都已存在，无需添加');
        return false;
      }
      
      // 添加到内存缓存
      if (_cachedLocalLessons != null) {
        _cachedLocalLessons!.addAll(lessonsToAdd);
        _cachedLocalLessons!.sort((a, b) => a.lesson.compareTo(b.lesson));
      }
      
      // 更新本地存储
      await _updateLocalCache();
      
      print('✅ 成功添加 ${lessonsToAdd.length} 个课程');
      return true;
    } catch (e) {
      print('❌ 添加课程失败: $e');
      return false;
    }
  }

  /// 更新本地缓存到 SharedPreferences
  Future<void> _updateLocalCache() async {
    try {
      if (_cachedLocalLessons != null) {
        final prefs = await SharedPreferences.getInstance();
        final lessonsJson = json.encode(_cachedLocalLessons!.map((lesson) => lesson.toJson()).toList());
        await prefs.setString('cached_lessons', lessonsJson);
        await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
        print('💾 本地缓存已更新，共 ${_cachedLocalLessons!.length} 个课程');
      }
    } catch (e) {
      print('❌ 更新本地缓存失败: $e');
    }
  }

  /// 获取课程统计信息
  Future<Map<String, dynamic>> getLessonStats() async {
    final stats = <String, dynamic>{};
    
    try {
      // 获取本地课程数量
      final localLessons = await getLocalLessons();
      stats['local_count'] = localLessons.length;
    } catch (e) {
      stats['local_count'] = 0;
    }

    try {
      // 获取远程课程数量
      if (_supabaseService.isInitialized) {
        final remoteLessons = await getRemoteLessons();
        stats['remote_count'] = remoteLessons.length;
      } else {
        stats['remote_count'] = 0;
      }
    } catch (e) {
      stats['remote_count'] = 0;
    }

    // 获取最后同步时间
    try {
      final prefs = await SharedPreferences.getInstance();
      stats['last_sync_time'] = prefs.getString('last_sync_time');
    } catch (e) {
      stats['last_sync_time'] = null;
    }

    // 其他状态信息
    stats['current_source'] = _currentSource.toString().split('.').last;
    stats['supabase_connected'] = _supabaseService.isInitialized;

    return stats;
  }
}