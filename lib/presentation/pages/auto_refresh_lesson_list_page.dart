import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/lesson_manager_service.dart';
import '../../services/supabase_service.dart';
import '../../models/lesson.dart';

class AutoRefreshLessonListPage extends StatefulWidget {
  const AutoRefreshLessonListPage({super.key});

  @override
  State<AutoRefreshLessonListPage> createState() => _AutoRefreshLessonListPageState();
}

class _AutoRefreshLessonListPageState extends State<AutoRefreshLessonListPage> {
  final LessonManagerService _lessonManager = LessonManagerService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 初始化并加载数据
  Future<void> _initializeAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📚 开始加载课程数据...');

      // 强制设置为混合模式，优先使用远程数据
      _lessonManager.setSource(LessonSource.mixed);
      
      // 强制刷新课程管理器缓存
      await _lessonManager.refreshAll();
      
      // 加载课程数据
      await _loadLessons();

      print('✅ 课程数据加载完成，共 ${_lessons.length} 个课程');

    } catch (e) {
      print('❌ 加载课程数据失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
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
      // 先尝试获取课程
      List<Lesson> lessons = await _lessonManager.getLessons();
      
      // 如果课程为空或很少，尝试直接从缓存加载
      if (lessons.isEmpty || lessons.length < 10) {
        print('🔄 课程数据较少，尝试从本地缓存重新加载...');
        
        // 强制刷新并重新获取
        await _lessonManager.refreshAll();
        lessons = await _lessonManager.getLessons();
        
        // 如果还是为空，尝试从 SharedPreferences 直接读取
        if (lessons.isEmpty) {
          lessons = await _loadFromSharedPreferences();
        }
      }

      setState(() {
        _lessons = lessons;
        _errorMessage = '';
      });

      print('📊 当前显示课程数量: ${_lessons.length}');

    } catch (e) {
      print('❌ 加载课程失败: $e');
      setState(() {
        _errorMessage = '加载课程失败: $e';
      });
    }
  }

  /// 直接从 SharedPreferences 加载课程数据
  Future<List<Lesson>> _loadFromSharedPreferences() async {
    try {
      print('🔍 尝试从 SharedPreferences 直接加载课程数据...');
      
      final prefs = await SharedPreferences.getInstance();
      final cachedLessonsJson = prefs.getString('cached_lessons');
      
      if (cachedLessonsJson != null && cachedLessonsJson.isNotEmpty) {
        final List<dynamic> lessonsData = json.decode(cachedLessonsJson);
        final lessons = lessonsData
            .map((lessonJson) => Lesson.fromJson(lessonJson))
            .toList();
        
        print('✅ 从 SharedPreferences 加载了 ${lessons.length} 个课程');
        return lessons;
      }
      
      print('⚠️ SharedPreferences 中没有缓存的课程数据');
      return [];
      
    } catch (e) {
      print('❌ 从 SharedPreferences 加载课程失败: $e');
      return [];
    }
  }

  /// 设置自动刷新
  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading) {
        _checkAndRefreshIfNeeded();
      }
    });
  }

  /// 检查并在需要时刷新
  Future<void> _checkAndRefreshIfNeeded() async {
    try {
      // 如果课程列表为空，尝试重新加载
      if (_lessons.isEmpty) {
        print('🔄 检测到课程列表为空，尝试重新加载...');
        await _loadLessons();
      }
    } catch (e) {
      print('❌ 自动刷新检查失败: $e');
    }
  }

  /// 手动刷新
  Future<void> _manualRefresh() async {
    await _initializeAndLoadData();
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
            onPressed: _isLoading ? null : _manualRefresh,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugInfo,
            tooltip: '调试信息',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    final isConnected = _supabaseService.isInitialized;
    final currentSource = _lessonManager.currentSource;

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
                  isConnected ? 'Supabase 已连接' : 'Supabase 未连接',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  '数据源: ${_getSourceName(currentSource.toString())} | 课程数: ${_lessons.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isConnected ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
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
              onPressed: _manualRefresh,
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
              '请检查网络连接或尝试刷新',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _manualRefresh,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _manualRefresh,
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
                      '${lesson.vocabulary.length} 个生词 | ${lesson.sentences.length} 个句子',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开课程: ${lesson.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 显示调试信息
  void _showDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLessonsJson = prefs.getString('cached_lessons');
    final lastSyncTime = prefs.getString('last_sync_time');
    
    final cachedCount = cachedLessonsJson != null ? 
        (json.decode(cachedLessonsJson) as List).length : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('调试信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('显示课程数: ${_lessons.length}'),
            Text('缓存课程数: $cachedCount'),
            Text('数据源: ${_getSourceName(_lessonManager.currentSource.toString())}'),
            Text('Supabase连接: ${_supabaseService.isInitialized ? '已连接' : '未连接'}'),
            if (lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text('最后同步: ${DateTime.parse(lastSyncTime).toLocal()}'),
            ],
          ],
        ),
        actions: [
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
}