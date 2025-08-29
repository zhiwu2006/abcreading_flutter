import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auto_sync_service.dart';
import '../../services/lesson_manager_service.dart';
import '../../services/supabase_service.dart';
import '../../models/lesson.dart';

class EnhancedLessonListPage extends StatefulWidget {
  const EnhancedLessonListPage({super.key});

  @override
  State<EnhancedLessonListPage> createState() => _EnhancedLessonListPageState();
}

class _EnhancedLessonListPageState extends State<EnhancedLessonListPage> {
  final AutoSyncService _autoSyncService = AutoSyncService.instance;
  final LessonManagerService _lessonManager = LessonManagerService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String _errorMessage = '';
  StreamSubscription<Map<String, dynamic>>? _syncSubscription;
  String _lastSyncMessage = '';
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupSyncListener();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📚 开始加载课程列表...');

      // 确保自动同步服务已初始化
      if (!_autoSyncService.getStatus()['is_initialized']) {
        await _autoSyncService.forceReinitialize();
      }

      // 设置课程管理器为混合模式（优先远程数据）
      _lessonManager.setSource(LessonSource.mixed);

      // 加载课程数据
      await _loadLessons();

      print('✅ 课程列表加载完成，共 ${_lessons.length} 个课程');

    } catch (e) {
      print('❌ 初始化数据失败: $e');
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载课程数据
  Future<void> _loadLessons() async {
    try {
      final lessons = await _lessonManager.getLessons();
      setState(() {
        _lessons = lessons;
        _errorMessage = '';
      });
    } catch (e) {
      print('❌ 加载课程失败: $e');
      setState(() {
        _errorMessage = '加载课程失败: $e';
      });
    }
  }

  /// 设置同步状态监听器
  void _setupSyncListener() {
    _syncSubscription = _autoSyncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _lastSyncMessage = status['message'] ?? '';
          _lastSyncTime = DateTime.tryParse(status['timestamp'] ?? '');
        });

        // 如果同步成功，重新加载课程列表
        if (status['success'] == true && 
            (status['type'] == 'initial_sync_completed' || 
             status['type'] == 'auto_sync_completed' ||
             status['type'] == 'manual_sync_completed' ||
             status['type'] == 'smart_sync_completed')) {
          print('🔄 检测到同步完成，重新加载课程列表...');
          _loadLessons();
        }

        // 显示同步状态消息
        _showSyncStatusMessage(status);
      }
    });
  }

  /// 显示同步状态消息
  void _showSyncStatusMessage(Map<String, dynamic> status) {
    final type = status['type'] as String?;
    final success = status['success'] as bool? ?? false;
    final message = status['message'] as String? ?? '';

    // 只显示重要的同步消息
    if (type == 'initial_sync_completed' || 
        type == 'manual_sync_completed' ||
        (type == 'auto_sync_completed' && (status['changed_count'] ?? 0) > 0)) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ $message' : '❌ $message'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 手动刷新数据
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 触发手动同步
      final syncResult = await _autoSyncService.manualSync();
      
      if (syncResult['success']) {
        // 同步成功后重新加载课程
        await _loadLessons();
      } else {
        // 同步失败，仍然尝试加载本地数据
        await _loadLessons();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ 同步失败，显示本地数据: ${syncResult['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 刷新数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 刷新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程列表'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: '刷新数据',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSyncSettings(),
            tooltip: '同步设置',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 构建同步状态栏
  Widget _buildSyncStatusBar() {
    final syncStatus = _autoSyncService.getStatus();
    final isConnected = syncStatus['supabase_connected'] as bool;
    final isAutoSyncEnabled = syncStatus['is_auto_sync_enabled'] as bool;
    final currentSource = syncStatus['lesson_manager_source'] as String;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.orange[50],
        border: Border(
          bottom: BorderSide(
            color: isConnected ? Colors.green[200]! : Colors.orange[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: isConnected ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? '已连接到 Supabase' : '未连接到 Supabase',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                if (_lastSyncMessage.isNotEmpty) ...[
                  Text(
                    _lastSyncMessage,
                    style: TextStyle(
                      fontSize: 10,
                      color: isConnected ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAutoSyncEnabled ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAutoSyncEnabled ? '自动同步' : '手动模式',
                style: TextStyle(
                  fontSize: 10,
                  color: isAutoSyncEnabled ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载课程数据...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无课程数据',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查网络连接或联系管理员',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];
          return _buildLessonCard(lesson, index);
        },
      ),
    );
  }

  /// 构建课程卡片
  Widget _buildLessonCard(Lesson lesson, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openLesson(lesson),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    '${lesson.lesson}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.vocabulary.length} 个生词',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开课程详情
  void _openLesson(Lesson lesson) {
    // 这里可以导航到课程详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开课程: ${lesson.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 显示同步设置对话框
  void _showSyncSettings() {
    final syncStatus = _autoSyncService.getStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supabase 连接: ${syncStatus['supabase_connected'] ? '已连接' : '未连接'}'),
            const SizedBox(height: 8),
            Text('自动同步: ${syncStatus['is_auto_sync_enabled'] ? '已启用' : '已禁用'}'),
            const SizedBox(height: 8),
            Text('同步间隔: ${syncStatus['sync_interval_minutes']} 分钟'),
            const SizedBox(height: 8),
            Text('数据源: ${_getSourceName(syncStatus['lesson_manager_source'])}'),
            const SizedBox(height: 16),
            if (_lastSyncTime != null) ...[
              Text('最后同步: ${_formatDateTime(_lastSyncTime!)}'),
              const SizedBox(height: 8),
            ],
            Text('课程数量: ${_lessons.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshData();
            },
            child: const Text('手动同步'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 获取数据源名称
  String _getSourceName(String source) {
    switch (source) {
      case 'LessonSource.local':
        return '本地数据';
      case 'LessonSource.remote':
        return '远程数据';
      case 'LessonSource.mixed':
        return '智能混合';
      default:
        return '未知';
    }
  }

  /// 格式化时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}