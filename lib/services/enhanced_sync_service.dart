import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'lesson_manager_service.dart';
import '../models/lesson.dart';
import '../data/default_lessons.dart';

/// 同步冲突解决策略
enum ConflictResolutionStrategy {
  /// 远程数据优先
  remoteWins,
  
  /// 本地数据优先
  localWins,
  
  /// 合并数据（保留两者的数据）
  merge,
  
  /// 手动解决（提示用户选择）
  manual
}

/// 同步历史记录项
class SyncHistoryItem {
  final DateTime timestamp;
  final bool success;
  final String message;
  final int changedItems;
  final String type;

  SyncHistoryItem({
    required this.timestamp,
    required this.success,
    required this.message,
    required this.changedItems,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'message': message,
      'changedItems': changedItems,
      'type': type,
    };
  }

  factory SyncHistoryItem.fromJson(Map<String, dynamic> json) {
    return SyncHistoryItem(
      timestamp: DateTime.parse(json['timestamp']),
      success: json['success'],
      message: json['message'],
      changedItems: json['changedItems'],
      type: json['type'],
    );
  }
}

class EnhancedSyncService {
  static final EnhancedSyncService _instance = EnhancedSyncService._internal();
  factory EnhancedSyncService() => _instance;
  
  EnhancedSyncService._internal() {
    // 初始化时加载同步历史
    _loadSyncHistory();
    
    // 设置自动同步定时器
    _setupAutoSync();
  }

  static EnhancedSyncService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService.instance;
  final LessonManagerService _lessonManager = LessonManagerService.instance;
  
  /// 同步历史记录
  List<SyncHistoryItem> _syncHistory = [];
  
  /// 自动同步定时器
  Timer? _autoSyncTimer;
  
  /// 默认冲突解决策略
  ConflictResolutionStrategy _defaultConflictStrategy = ConflictResolutionStrategy.remoteWins;
  
  /// 是否启用自动同步
  bool _autoSyncEnabled = false;
  
  /// 自动同步间隔（分钟）
  int _autoSyncInterval = 30;
  
  /// 同步状态流
  final _syncStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get syncStatusStream => _syncStatusController.stream;

  /// 强制从远程同步到本地（清除所有缓存）
  Future<Map<String, dynamic>> forceRemoteToLocalSync() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': <String, dynamic>{},
    };

    try {
      print('🔄 开始强制从远程同步到本地...');

      // 1. 检查 Supabase 连接
      if (!_supabaseService.isInitialized) {
        result['message'] = 'Supabase 服务未初始化';
        return result;
      }

      // 2. 清除所有本地缓存
      print('🗑️ 清除所有本地缓存...');
      await _clearAllLocalCache();
      result['details']['cache_cleared'] = true;

      // 3. 直接从 Supabase 获取最新数据
      print('📡 从 Supabase 获取最新课程数据...');
      final remoteLessons = await _fetchLatestRemoteLessons();
      
      if (remoteLessons.isEmpty) {
        result['message'] = '远程数据库中没有课程数据';
        result['details']['remote_lessons_count'] = 0;
        return result;
      }

      result['details']['remote_lessons_count'] = remoteLessons.length;

      // 4. 将远程数据保存到本地存储
      print('💾 保存远程数据到本地存储...');
      await _saveRemoteDataToLocal(remoteLessons);
      result['details']['saved_to_local'] = true;

      // 5. 强制刷新 LessonManagerService 缓存
      print('🔄 刷新课程管理器缓存...');
      await _lessonManager.refreshAll();
      result['details']['manager_refreshed'] = true;

      // 6. 验证同步结果
      print('✅ 验证同步结果...');
      final localLessons = await _lessonManager.getLocalLessons();
      result['details']['local_lessons_count'] = localLessons.length;
      result['details']['sync_successful'] = localLessons.length == remoteLessons.length;

      // 7. 比较数据一致性
      if (localLessons.length == remoteLessons.length) {
        final firstLocal = localLessons.isNotEmpty ? localLessons.first : null;
        final firstRemote = remoteLessons.isNotEmpty ? remoteLessons.first : null;
        
        if (firstLocal != null && firstRemote != null) {
          result['details']['data_consistency'] = {
            'local_first_title': firstLocal.title,
            'remote_first_title': firstRemote.title,
            'titles_match': firstLocal.title == firstRemote.title,
          };
        }
      }

      result['success'] = true;
      result['message'] = '强制同步完成，本地数据已更新';

    } catch (e) {
      result['message'] = '强制同步失败: $e';
      result['details']['error'] = e.toString();
      print('❌ 强制同步失败: $e');
    }

    return result;
  }

  /// 清除所有本地缓存
  Future<void> _clearAllLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 清除课程缓存
      await prefs.remove('cached_lessons');
      
      // 清除同步时间
      await prefs.remove('last_sync_time');
      
      // 清除 LessonManagerService 的内存缓存
      _lessonManager.setSource(LessonSource.local); // 临时切换
      await _lessonManager.refreshAll();
      
      print('✅ 所有本地缓存已清除');
    } catch (e) {
      print('❌ 清除本地缓存失败: $e');
      rethrow;
    }
  }

  /// 直接从 Supabase 获取最新课程数据
  Future<List<Lesson>> _fetchLatestRemoteLessons() async {
    try {
      final response = await _supabaseService.client
          .from('lessons')
          .select()
          .order('lesson_number');

      if (response.isEmpty) {
        return [];
      }

      return response.map<Lesson>((json) => Lesson.fromSupabaseJson(json)).toList();
    } catch (e) {
      print('❌ 获取远程课程数据失败: $e');
      rethrow;
    }
  }

  /// 将远程数据保存到本地存储
  Future<void> _saveRemoteDataToLocal(List<Lesson> remoteLessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 转换为本地 JSON 格式并保存
      final lessonsJson = json.encode(
        remoteLessons.map((lesson) => lesson.toJson()).toList()
      );
      
      await prefs.setString('cached_lessons', lessonsJson);
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
      
      print('✅ 远程数据已保存到本地存储');
    } catch (e) {
      print('❌ 保存远程数据到本地失败: $e');
      rethrow;
    }
  }

  /// 智能同步（检查数据差异后同步）
  Future<Map<String, dynamic>> smartSync() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'changes': <String, dynamic>{},
    };

    try {
      print('🧠 开始智能同步...');

      // 1. 获取本地和远程数据
      final localLessons = await _lessonManager.getLocalLessons();
      final remoteLessons = await _fetchLatestRemoteLessons();

      result['changes']['local_count'] = localLessons.length;
      result['changes']['remote_count'] = remoteLessons.length;

      // 2. 比较数据差异
      final differences = _compareData(localLessons, remoteLessons);
      result['changes']['differences'] = differences;

      // 3. 如果有差异，执行同步
      if (differences['has_differences'] == true) {
        print('📊 发现数据差异，执行同步...');
        final syncResult = await forceRemoteToLocalSync();
        result['success'] = syncResult['success'];
        result['message'] = syncResult['message'];
        result['changes']['sync_details'] = syncResult['details'];
      } else {
        print('✅ 本地和远程数据一致，无需同步');
        result['success'] = true;
        result['message'] = '数据已是最新，无需同步';
      }

    } catch (e) {
      result['message'] = '智能同步失败: $e';
      print('❌ 智能同步失败: $e');
    }

    return result;
  }

  /// 比较本地和远程数据差异
  Map<String, dynamic> _compareData(List<Lesson> localLessons, List<Lesson> remoteLessons) {
    final differences = <String, dynamic>{
      'has_differences': false,
      'count_difference': remoteLessons.length - localLessons.length,
      'different_lessons': <int>[],
    };

    // 比较数量
    if (localLessons.length != remoteLessons.length) {
      differences['has_differences'] = true;
      differences['count_mismatch'] = true;
    }

    // 比较内容（如果数量相同）
    if (localLessons.length == remoteLessons.length) {
      for (int i = 0; i < localLessons.length; i++) {
        final local = localLessons[i];
        final remote = remoteLessons[i];
        
        if (local.title != remote.title || 
            local.content != remote.content ||
            local.vocabulary.length != remote.vocabulary.length ||
            local.sentences.length != remote.sentences.length ||
            local.questions.length != remote.questions.length) {
          differences['has_differences'] = true;
          differences['different_lessons'].add(local.lesson);
        }
      }
    }

    return differences;
  }

  /// 上传本地默认数据到远程（如果远程为空）
  Future<Map<String, dynamic>> uploadDefaultDataIfEmpty() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'uploaded': false,
    };

    try {
      print('🔍 检查远程数据库是否为空...');
      
      final remoteLessons = await _fetchLatestRemoteLessons();
      
      if (remoteLessons.isEmpty) {
        print('📤 远程数据库为空，上传默认课程数据...');
        
        final uploadSuccess = await _supabaseService.insertLessons(defaultLessons);
        
        if (uploadSuccess) {
          result['success'] = true;
          result['uploaded'] = true;
          result['message'] = '成功上传 ${defaultLessons.length} 个默认课程到远程数据库';
          print('✅ 默认课程数据上传成功');
        } else {
          result['message'] = '上传默认课程数据失败';
          print('❌ 上传默认课程数据失败');
        }
      } else {
        result['success'] = true;
        result['uploaded'] = false;
        result['message'] = '远程数据库已有 ${remoteLessons.length} 个课程，无需上传';
        print('✅ 远程数据库已有数据，无需上传');
      }

    } catch (e) {
      result['message'] = '检查或上传数据时发生错误: $e';
      print('❌ 检查或上传数据失败: $e');
    }

    return result;
  }

  /// 打印同步状态
  Future<void> printSyncStatus() async {
    print('📊 当前同步状态:');
    
    try {
      // 获取本地课程数量
      final localLessons = await _lessonManager.getLocalLessons();
      print('  本地课程数量: ${localLessons.length}');
      
      // 获取远程课程数量
      if (_supabaseService.isInitialized) {
        final remoteLessons = await _fetchLatestRemoteLessons();
        print('  远程课程数量: ${remoteLessons.length}');
        
        // 获取最后同步时间
        final prefs = await SharedPreferences.getInstance();
        final lastSyncTime = prefs.getString('last_sync_time');
        if (lastSyncTime != null) {
          final syncTime = DateTime.parse(lastSyncTime);
          print('  最后同步时间: ${syncTime.toLocal()}');
        } else {
          print('  最后同步时间: 从未同步');
        }
        
        // 数据一致性
        if (localLessons.length == remoteLessons.length) {
          print('  数据状态: ✅ 一致');
        } else {
          print('  数据状态: ⚠️ 不一致');
        }
        
        // 自动同步状态
        print('  自动同步: ${_autoSyncEnabled ? '✅ 已启用' : '❌ 已禁用'}');
        if (_autoSyncEnabled) {
          print('  自动同步间隔: $_autoSyncInterval 分钟');
        }
        
        // 同步历史
        print('  同步历史记录: ${_syncHistory.length} 条');
      } else {
        print('  远程连接: ❌ 未连接');
      }
      
      // 当前数据源
      print('  当前数据源: ${_lessonManager.currentSource}');
      
    } catch (e) {
      print('  状态检查失败: $e');
    }
  }
  
  /// 加载同步历史记录
  Future<void> _loadSyncHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('sync_history');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _syncHistory = historyList
            .map((item) => SyncHistoryItem.fromJson(item))
            .toList();
        
        print('📜 已加载 ${_syncHistory.length} 条同步历史记录');
      }
    } catch (e) {
      print('❌ 加载同步历史记录失败: $e');
      _syncHistory = [];
    }
  }
  
  /// 保存同步历史记录
  Future<void> _saveSyncHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 限制历史记录数量，只保留最近的50条
      if (_syncHistory.length > 50) {
        _syncHistory = _syncHistory.sublist(_syncHistory.length - 50);
      }
      
      final historyJson = json.encode(
        _syncHistory.map((item) => item.toJson()).toList()
      );
      
      await prefs.setString('sync_history', historyJson);
    } catch (e) {
      print('❌ 保存同步历史记录失败: $e');
    }
  }
  
  /// 添加同步历史记录
  Future<void> _addSyncHistoryItem(SyncHistoryItem item) async {
    _syncHistory.add(item);
    await _saveSyncHistory();
  }
  
  /// 获取同步历史记录
  List<SyncHistoryItem> getSyncHistory() {
    return List.unmodifiable(_syncHistory);
  }
  
  /// 清除同步历史记录
  Future<void> clearSyncHistory() async {
    _syncHistory.clear();
    await _saveSyncHistory();
    print('🗑️ 同步历史记录已清除');
  }
  
  /// 设置自动同步
  Future<void> _setupAutoSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;
      _autoSyncInterval = prefs.getInt('auto_sync_interval') ?? 30;
      
      if (_autoSyncEnabled) {
        _startAutoSync();
      }
    } catch (e) {
      print('❌ 设置自动同步失败: $e');
    }
  }
  
  /// 启动自动同步
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      Duration(minutes: _autoSyncInterval),
      (_) async {
        print('⏰ 执行自动同步...');
        await smartSync();
      }
    );
    print('⏰ 自动同步已启动，间隔: $_autoSyncInterval 分钟');
  }
  
  /// 停止自动同步
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('⏰ 自动同步已停止');
  }
  
  /// 设置自动同步状态
  Future<void> setAutoSync({required bool enabled, int? intervalMinutes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSyncEnabled = enabled;
      
      if (intervalMinutes != null && intervalMinutes > 0) {
        _autoSyncInterval = intervalMinutes;
        await prefs.setInt('auto_sync_interval', intervalMinutes);
      }
      
      await prefs.setBool('auto_sync_enabled', enabled);
      
      if (enabled) {
        _startAutoSync();
      } else {
        _stopAutoSync();
      }
      
      print('⏰ 自动同步已${enabled ? '启用' : '禁用'}，间隔: $_autoSyncInterval 分钟');
    } catch (e) {
      print('❌ 设置自动同步状态失败: $e');
    }
  }
  
  /// 获取自动同步状态
  Map<String, dynamic> getAutoSyncStatus() {
    return {
      'enabled': _autoSyncEnabled,
      'interval': _autoSyncInterval,
      'isRunning': _autoSyncTimer != null,
    };
  }
  
  /// 增量同步（只同步变化的数据）
  Future<Map<String, dynamic>> incrementalSync({
    ConflictResolutionStrategy? conflictStrategy
  }) async {
    final strategy = conflictStrategy ?? _defaultConflictStrategy;
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'changes': <String, dynamic>{},
    };
    
    try {
      print('🔄 开始增量同步...');
      
      // 1. 检查 Supabase 连接
      if (!_supabaseService.isInitialized) {
        result['message'] = 'Supabase 服务未初始化';
        return result;
      }
      
      // 2. 获取本地和远程数据
      final localLessons = await _lessonManager.getLocalLessons();
      final remoteLessons = await _fetchLatestRemoteLessons();
      
      // 3. 找出需要更新的课程
      final changedLessons = _identifyChangedLessons(localLessons, remoteLessons);
      result['changes']['changed_lessons_count'] = changedLessons.length;
      
      if (changedLessons.isEmpty) {
        result['success'] = true;
        result['message'] = '没有需要同步的数据变更';
        
        // 记录同步历史
        await _addSyncHistoryItem(SyncHistoryItem(
          timestamp: DateTime.now(),
          success: true,
          message: '增量同步 - 没有变更',
          changedItems: 0,
          type: '增量同步',
        ));
        
        return result;
      }
      
      // 4. 根据冲突解决策略处理变更
      final resolvedLessons = await _resolveConflicts(
        changedLessons, 
        localLessons, 
        remoteLessons, 
        strategy
      );
      
      // 5. 应用变更
      if (resolvedLessons.isNotEmpty) {
        // 更新本地数据
        final allLessons = List<Lesson>.from(localLessons);
        
        for (final lesson in resolvedLessons) {
          final index = allLessons.indexWhere((l) => l.lesson == lesson.lesson);
          if (index >= 0) {
            allLessons[index] = lesson;
          } else {
            allLessons.add(lesson);
          }
        }
        
        // 保存到本地
        await _saveRemoteDataToLocal(allLessons);
        
        // 刷新课程管理器
        await _lessonManager.refreshAll();
        
        result['success'] = true;
        result['message'] = '增量同步完成，已更新 ${resolvedLessons.length} 个课程';
        result['changes']['updated_lessons'] = resolvedLessons.map((l) => l.lesson).toList();
        
        // 记录同步历史
        await _addSyncHistoryItem(SyncHistoryItem(
          timestamp: DateTime.now(),
          success: true,
          message: '增量同步 - 已更新 ${resolvedLessons.length} 个课程',
          changedItems: resolvedLessons.length,
          type: '增量同步',
        ));
        
        // 通知状态变化
        _syncStatusController.add({
          'type': 'incremental_sync_completed',
          'updated_count': resolvedLessons.length,
        });
      }
      
    } catch (e) {
      result['message'] = '增量同步失败: $e';
      print('❌ 增量同步失败: $e');
      
      // 记录同步历史
      await _addSyncHistoryItem(SyncHistoryItem(
        timestamp: DateTime.now(),
        success: false,
        message: '增量同步失败: $e',
        changedItems: 0,
        type: '增量同步',
      ));
    }
    
    return result;
  }
  
  /// 识别变更的课程
  List<Map<String, dynamic>> _identifyChangedLessons(
    List<Lesson> localLessons, 
    List<Lesson> remoteLessons
  ) {
    final changedLessons = <Map<String, dynamic>>[];
    
    // 创建本地课程的映射表，以课程编号为键
    final localMap = {for (var lesson in localLessons) lesson.lesson: lesson};
    final remoteMap = {for (var lesson in remoteLessons) lesson.lesson: lesson};
    
    // 检查远程课程是否在本地存在或有变更
    for (final remoteLessonNumber in remoteMap.keys) {
      final remoteLessonData = remoteMap[remoteLessonNumber]!;
      final localLessonData = localMap[remoteLessonNumber];
      
      if (localLessonData == null) {
        // 本地不存在此课程，需要添加
        changedLessons.add({
          'lesson': remoteLessonNumber,
          'type': 'new',
          'remote': remoteLessonData,
          'local': null,
        });
      } else if (_isLessonDifferent(localLessonData, remoteLessonData)) {
        // 课程内容有变化，需要更新
        changedLessons.add({
          'lesson': remoteLessonNumber,
          'type': 'changed',
          'remote': remoteLessonData,
          'local': localLessonData,
        });
      }
    }
    
    // 检查本地课程是否在远程不存在（可能需要上传）
    for (final localLessonNumber in localMap.keys) {
      if (!remoteMap.containsKey(localLessonNumber)) {
        changedLessons.add({
          'lesson': localLessonNumber,
          'type': 'local_only',
          'remote': null,
          'local': localMap[localLessonNumber],
        });
      }
    }
    
    return changedLessons;
  }
  
  /// 判断两个课程是否有差异
  bool _isLessonDifferent(Lesson local, Lesson remote) {
    if (local.title != remote.title || 
        local.content != remote.content ||
        local.vocabulary.length != remote.vocabulary.length) {
      return true;
    }
    
    // 比较词汇表内容
    for (int i = 0; i < local.vocabulary.length; i++) {
      if (i >= remote.vocabulary.length) return true;
      
      final localVocab = local.vocabulary[i];
      final remoteVocab = remote.vocabulary[i];
      
      if (localVocab.word != remoteVocab.word || 
          localVocab.meaning != remoteVocab.meaning) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 根据冲突解决策略处理变更
  Future<List<Lesson>> _resolveConflicts(
    List<Map<String, dynamic>> changedLessons,
    List<Lesson> localLessons,
    List<Lesson> remoteLessons,
    ConflictResolutionStrategy strategy
  ) async {
    final resolvedLessons = <Lesson>[];
    
    for (final change in changedLessons) {
      final type = change['type'];
      final remoteLessonData = change['remote'];
      final localLessonData = change['local'];
      
      if (type == 'new') {
        // 新课程，直接添加
        resolvedLessons.add(remoteLessonData);
      } else if (type == 'changed') {
        // 有冲突，根据策略解决
        switch (strategy) {
          case ConflictResolutionStrategy.remoteWins:
            resolvedLessons.add(remoteLessonData);
            break;
          case ConflictResolutionStrategy.localWins:
            // 不做任何操作，保留本地数据
            break;
          case ConflictResolutionStrategy.merge:
            // 合并数据（这里简单实现，可以根据需要扩展）
            final mergedLesson = await _mergeLessons(localLessonData, remoteLessonData);
            resolvedLessons.add(mergedLesson);
            break;
          case ConflictResolutionStrategy.manual:
            // 手动解决需要UI交互，这里先跳过
            // 实际应用中可以通过回调或事件通知UI层处理
            print('⚠️ 课程 ${change['lesson']} 需要手动解决冲突');
            break;
        }
      } else if (type == 'local_only') {
        // 本地独有的课程，可以考虑上传到远程
        // 这里暂不处理，可以根据需要扩展
      }
    }
    
    return resolvedLessons;
  }
  
  /// 合并两个课程的数据
  Future<Lesson> _mergeLessons(Lesson local, Lesson remote) async {
    // 这里实现一个简单的合并策略
    // 可以根据实际需求进行更复杂的合并逻辑
    
    // 标题和内容使用较新的版本
    final title = remote.title;
    final content = remote.content;
    
    // 合并词汇表
    final localVocabMap = {for (var v in local.vocabulary) v.word: v};
    final remoteVocabMap = {for (var v in remote.vocabulary) v.word: v};
    
    final allWords = <String>{...localVocabMap.keys, ...remoteVocabMap.keys}.toList();
    final mergedVocabulary = allWords.map((word) {
      final localVocab = localVocabMap[word];
      final remoteVocab = remoteVocabMap[word];
      
      if (localVocab == null) return remoteVocab!;
      if (remoteVocab == null) return localVocab;
      
      // 两者都有，使用远程版本
      return remoteVocab;
    }).toList();
    
    return Lesson(
      lesson: remote.lesson,
      title: title,
      content: content,
      vocabulary: mergedVocabulary,
      sentences: remote.sentences, // 使用远程版本的句子
      questions: remote.questions, // 使用远程版本的问题
    );
  }
  
  /// 设置默认冲突解决策略
  void setDefaultConflictStrategy(ConflictResolutionStrategy strategy) {
    _defaultConflictStrategy = strategy;
    print('🔧 默认冲突解决策略已设置为: $strategy');
  }
  
  /// 获取默认冲突解决策略
  ConflictResolutionStrategy getDefaultConflictStrategy() {
    return _defaultConflictStrategy;
  }
  
  /// 销毁服务
  void dispose() {
    _autoSyncTimer?.cancel();
    _syncStatusController.close();
  }
}