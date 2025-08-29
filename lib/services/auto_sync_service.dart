import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_sync_service.dart';
import 'lesson_manager_service.dart';
import 'supabase_service.dart';

/// 自动同步服务 - 负责自动将 Supabase 数据加载到课程列表
class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal() {
    _initialize();
  }

  static AutoSyncService get instance => _instance;

  final EnhancedSyncService _enhancedSync = EnhancedSyncService.instance;
  final LessonManagerService _lessonManager = LessonManagerService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  Timer? _autoSyncTimer;
  Timer? _connectionCheckTimer;
  bool _isAutoSyncEnabled = true;
  int _syncIntervalMinutes = 5; // 默认5分钟同步一次
  bool _isInitialized = false;

  /// 同步状态流控制器
  final _syncStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get syncStatusStream => _syncStatusController.stream;

  /// 初始化自动同步服务
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 初始化自动同步服务...');

      // 加载配置
      await _loadConfiguration();

      // 设置连接检查定时器
      _setupConnectionCheck();

      // 如果 Supabase 已连接，立即执行一次同步
      if (_supabaseService.isInitialized) {
        await _performInitialSync();
      }

      // 启动自动同步
      if (_isAutoSyncEnabled) {
        _startAutoSync();
      }

      _isInitialized = true;
      print('✅ 自动同步服务初始化完成');

    } catch (e) {
      print('❌ 自动同步服务初始化失败: $e');
    }
  }

  /// 加载配置
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      _syncIntervalMinutes = prefs.getInt('auto_sync_interval') ?? 5;
      
      print('📋 自动同步配置: 启用=$_isAutoSyncEnabled, 间隔=${_syncIntervalMinutes}分钟');
    } catch (e) {
      print('⚠️ 加载自动同步配置失败: $e');
    }
  }

  /// 保存配置
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_sync_enabled', _isAutoSyncEnabled);
      await prefs.setInt('auto_sync_interval', _syncIntervalMinutes);
    } catch (e) {
      print('⚠️ 保存自动同步配置失败: $e');
    }
  }

  /// 设置连接检查定时器
  void _setupConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 30), // 每30秒检查一次连接
      (_) => _checkConnectionAndSync(),
    );
  }

  /// 检查连接并同步
  Future<void> _checkConnectionAndSync() async {
    if (!_isAutoSyncEnabled) return;

    try {
      // 检查 Supabase 连接状态
      if (_supabaseService.isInitialized) {
        // 如果自动同步定时器没有运行，启动它
        if (_autoSyncTimer == null) {
          _startAutoSync();
        }
      } else {
        // 如果连接断开，停止自动同步
        if (_autoSyncTimer != null) {
          _stopAutoSync();
          print('⚠️ Supabase 连接断开，暂停自动同步');
        }
      }
    } catch (e) {
      print('⚠️ 连接检查失败: $e');
    }
  }

  /// 执行初始同步
  Future<void> _performInitialSync() async {
    try {
      print('🔄 执行初始数据同步...');

      // 首先检查是否需要上传默认数据
      final uploadResult = await _enhancedSync.uploadDefaultDataIfEmpty();
      if (uploadResult['uploaded'] == true) {
        print('📤 已上传默认数据到远程');
      }

      // 执行智能同步
      final syncResult = await _enhancedSync.smartSync();
      
      if (syncResult['success']) {
        print('✅ 初始同步完成');
        
        // 通知同步状态
        _syncStatusController.add({
          'type': 'initial_sync_completed',
          'success': true,
          'message': '初始同步完成',
          'timestamp': DateTime.now().toIso8601String(),
        });

        // 确保课程管理器使用混合模式
        _lessonManager.setSource(LessonSource.mixed);
        
      } else {
        print('⚠️ 初始同步失败: ${syncResult['message']}');
        
        _syncStatusController.add({
          'type': 'initial_sync_failed',
          'success': false,
          'message': syncResult['message'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

    } catch (e) {
      print('❌ 初始同步异常: $e');
      
      _syncStatusController.add({
        'type': 'initial_sync_error',
        'success': false,
        'message': '初始同步异常: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 启动自动同步
  void _startAutoSync() {
    if (!_isAutoSyncEnabled || !_supabaseService.isInitialized) {
      return;
    }

    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      Duration(minutes: _syncIntervalMinutes),
      (_) => _performAutoSync(),
    );

    print('⏰ 自动同步已启动，间隔: $_syncIntervalMinutes 分钟');
  }

  /// 停止自动同步
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('⏰ 自动同步已停止');
  }

  /// 执行自动同步
  Future<void> _performAutoSync() async {
    if (!_isAutoSyncEnabled || !_supabaseService.isInitialized) {
      return;
    }

    try {
      print('🔄 执行自动同步...');

      // 执行增量同步
      final syncResult = await _enhancedSync.incrementalSync();
      
      if (syncResult['success']) {
        final changedCount = syncResult['changes']['changed_lessons_count'] ?? 0;
        
        if (changedCount > 0) {
          print('✅ 自动同步完成，更新了 $changedCount 个课程');
          
          _syncStatusController.add({
            'type': 'auto_sync_completed',
            'success': true,
            'message': '自动同步完成，更新了 $changedCount 个课程',
            'changed_count': changedCount,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          print('✅ 自动同步完成，数据已是最新');
          
          _syncStatusController.add({
            'type': 'auto_sync_no_changes',
            'success': true,
            'message': '数据已是最新',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        print('⚠️ 自动同步失败: ${syncResult['message']}');
        
        _syncStatusController.add({
          'type': 'auto_sync_failed',
          'success': false,
          'message': syncResult['message'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

    } catch (e) {
      print('❌ 自动同步异常: $e');
      
      _syncStatusController.add({
        'type': 'auto_sync_error',
        'success': false,
        'message': '自动同步异常: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 手动触发同步
  Future<Map<String, dynamic>> manualSync() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
    };

    try {
      print('🔄 手动触发同步...');

      if (!_supabaseService.isInitialized) {
        result['message'] = 'Supabase 未连接，无法同步';
        return result;
      }

      // 执行强制同步
      final syncResult = await _enhancedSync.forceRemoteToLocalSync();
      
      result['success'] = syncResult['success'];
      result['message'] = syncResult['message'];
      result['details'] = syncResult['details'];

      if (syncResult['success']) {
        _syncStatusController.add({
          'type': 'manual_sync_completed',
          'success': true,
          'message': '手动同步完成',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

    } catch (e) {
      result['message'] = '手动同步失败: $e';
      print('❌ 手动同步失败: $e');
    }

    return result;
  }

  /// 启用/禁用自动同步
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _isAutoSyncEnabled = enabled;
    await _saveConfiguration();

    if (enabled && _supabaseService.isInitialized) {
      _startAutoSync();
      print('✅ 自动同步已启用');
    } else {
      _stopAutoSync();
      print('❌ 自动同步已禁用');
    }

    _syncStatusController.add({
      'type': 'auto_sync_setting_changed',
      'enabled': enabled,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 设置同步间隔
  Future<void> setSyncInterval(int minutes) async {
    if (minutes < 1) {
      throw ArgumentError('同步间隔不能小于1分钟');
    }

    _syncIntervalMinutes = minutes;
    await _saveConfiguration();

    // 重启自动同步以应用新间隔
    if (_isAutoSyncEnabled && _supabaseService.isInitialized) {
      _startAutoSync();
    }

    print('⏰ 同步间隔已设置为 $minutes 分钟');

    _syncStatusController.add({
      'type': 'sync_interval_changed',
      'interval': minutes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 获取自动同步状态
  Map<String, dynamic> getStatus() {
    return {
      'is_initialized': _isInitialized,
      'is_auto_sync_enabled': _isAutoSyncEnabled,
      'sync_interval_minutes': _syncIntervalMinutes,
      'is_auto_sync_running': _autoSyncTimer != null,
      'is_connection_check_running': _connectionCheckTimer != null,
      'supabase_connected': _supabaseService.isInitialized,
      'lesson_manager_source': _lessonManager.currentSource.toString(),
    };
  }

  /// 强制重新初始化
  Future<void> forceReinitialize() async {
    print('🔄 强制重新初始化自动同步服务...');
    
    // 停止所有定时器
    _autoSyncTimer?.cancel();
    _connectionCheckTimer?.cancel();
    
    // 重置状态
    _isInitialized = false;
    
    // 重新初始化
    await _initialize();
  }

  /// 获取同步历史
  List<Map<String, dynamic>> getSyncHistory() {
    return _enhancedSync.getSyncHistory()
        .map((item) => {
              'timestamp': item.timestamp.toIso8601String(),
              'success': item.success,
              'message': item.message,
              'changed_items': item.changedItems,
              'type': item.type,
            })
        .toList();
  }

  /// 清除同步历史
  Future<void> clearSyncHistory() async {
    await _enhancedSync.clearSyncHistory();
    
    _syncStatusController.add({
      'type': 'sync_history_cleared',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 销毁服务
  void dispose() {
    _autoSyncTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _syncStatusController.close();
    print('🗑️ 自动同步服务已销毁');
  }
}