import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'models/lesson.dart';
import 'data/default_lessons.dart';
import 'providers/app_provider.dart';
import 'services/tts_service.dart';
import 'services/sync_progress_service.dart';
import 'services/progress_service.dart';
import 'services/supabase_service.dart';
import 'services/lesson_manager_service.dart';
import 'services/auto_sync_service.dart';
import 'core/config/supabase_config.dart';
import 'presentation/pages/supabase_config_page.dart';
import 'presentation/pages/lesson_source_page.dart';
import 'presentation/pages/enhanced_lesson_list_page.dart';
import 'presentation/pages/auto_refresh_lesson_list_page.dart';
import 'utils/connection_test.dart';
import 'utils/cache_debug_tool.dart';
import 'utils/provider_refresh_tool.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Supabase
  try {
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();
    
    print('🔄 正在初始化Supabase...');
    print('URL: $url');
    print('Key: ${anonKey.substring(0, 20)}...');
    
    // 检查配置是否有效
    final isConfigValid = await SupabaseConfig.isConfigValid();
    if (isConfigValid) {
      await SupabaseService.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      // 测试连接
      final connectionTest = await SupabaseService.instance.testConnection();
      if (connectionTest) {
        print('✅ Supabase初始化并连接成功');
      } else {
        print('⚠️ Supabase初始化成功但连接测试失败');
      }
    } else {
      print('⚠️ Supabase配置无效，将使用本地存储模式');
    }
  } catch (e) {
    print('❌ Supabase初始化失败: $e');
    // 继续运行应用，使用本地存储
  }
  
  // 初始化其他服务
  await TTSService().initialize();
  await SyncProgressService().initialize();
  
  // 初始化自动同步服务
  final autoSyncService = AutoSyncService.instance;
  print('🚀 自动同步服务已启动');
  
  runApp(const EnglishLearningApp());
}

class EnglishLearningApp extends StatelessWidget {
  const EnglishLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: '英语阅读理解学习平台',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'TimesNewRoman',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ReadingPreferences {
  final int fontSize;
  final String fontFamily;
  final bool showVocabularyHighlight;

  const ReadingPreferences({
    this.fontSize = 24,
    this.fontFamily = 'Times',
    this.showVocabularyHighlight = true,
  });

  ReadingPreferences copyWith({
    int? fontSize,
    String? fontFamily,
    bool? showVocabularyHighlight,
  }) {
    return ReadingPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      showVocabularyHighlight: showVocabularyHighlight ?? this.showVocabularyHighlight,
    );
  }

  /// 获取字体样式
  String get fontFamilyStyle {
    switch (fontFamily) {
      case 'Times':
        return 'TimesNewRoman';
      case 'Arial':
        return 'Arial';
      case 'Georgia':
        return 'Georgia';
      case 'Roboto':
      default:
        return 'Roboto';
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentLessonIndex = 0;
  ReadingPreferences readingPreferences = const ReadingPreferences();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TTSService _ttsService = TTSService();
  final SyncProgressService _progressService = SyncProgressService();
  bool _isLoadingProgress = true;
  bool _showChrome = true; // 控制“第几课”标题栏与Tab栏显示

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  /// 加载学习进度
  Future<void> _loadProgress() async {
    try {
      final progress = await _progressService.loadProgress();
      if (progress != null && progress.currentLessonIndex < defaultLessons.length) {
        setState(() {
          currentLessonIndex = progress.currentLessonIndex;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📖 恢复学习进度: 第${progress.currentLessonNumber}课'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('加载学习进度失败: $e');
    } finally {
      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  Future<void> _initApp() async {
    // 先加载课程（覆盖默认课程为远程/本地缓存），再恢复学习进度
    await _loadLessonsFromManager();
    await _loadProgress();
  }

  Future<void> _loadLessonsFromManager() async {
    try {
      final lessons = await LessonManagerService.instance.getLessons();
      if (lessons.isNotEmpty) {
        final prevIndex = currentLessonIndex;
        // 覆盖默认课程列表为最新数据（支持 143 个）
        defaultLessons
          ..clear()
          ..addAll(lessons);
        // 修正当前索引不越界
        setState(() {
          currentLessonIndex = prevIndex >= defaultLessons.length
              ? (defaultLessons.isNotEmpty ? defaultLessons.length - 1 : 0)
              : prevIndex;
        });
      }
    } catch (e) {
      debugPrint('加载课程列表失败: $e');
    }
  }

  /// 保存学习进度
  Future<void> _saveProgress() async {
    if (currentLessonIndex < defaultLessons.length) {
      await _progressService.updateCurrentLesson(currentLessonIndex);
    }
  }

  /// 重置学习进度
  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置学习进度'),
        content: const Text('确定要重置学习进度吗？这将清除所有学习记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _progressService.clearProgress();
      if (success) {
        setState(() {
          currentLessonIndex = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 学习进度已重置'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 重置失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '正在加载学习进度...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '英语阅读理解学习平台',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetProgress,
            tooltip: '重置学习进度',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _showChrome ? _buildLessonSelector() : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LessonContent(
                    lesson: defaultLessons[currentLessonIndex],
                    readingPreferences: readingPreferences,
                    ttsService: _ttsService,
                    progressService: _progressService,
                    showChrome: _showChrome,
                    onChromeVisibilityChange: (show) {
                      if (show != _showChrome) {
                        setState(() => _showChrome = show);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  '英语学习平台',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '提升您的英语阅读能力',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ReadingSettings(
                  preferences: readingPreferences,
                  onPreferencesChange: (newPreferences) {
                    setState(() {
                      readingPreferences = newPreferences;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildProgressInfo(),
                const SizedBox(height: 16),
                _buildLessonList(),
                const SizedBox(height: 16),
                _buildEnhancedLessonListSection(),
                const SizedBox(height: 16),
                _buildAutoRefreshLessonListSection(),
                const SizedBox(height: 16),
                _buildCacheDebugSection(),
                const SizedBox(height: 16),
                _buildLessonSourceSection(),
                const SizedBox(height: 16),
                _buildSupabaseSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLessonListSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.teal[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '智能课程列表',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '自动同步Supabase数据',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.list_alt,
              color: Colors.teal[600],
            ),
            title: const Text('查看课程列表'),
            subtitle: const Text(
              '自动加载最新的Supabase课程数据',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedLessonListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRefreshLessonListSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动刷新课程列表',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '解决同步后显示问题',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.refresh,
              color: Colors.orange[600],
            ),
            title: const Text('自动刷新课程列表'),
            subtitle: const Text(
              '自动检测并刷新同步后的课程数据',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AutoRefreshLessonListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCacheDebugSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.red[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '缓存调试工具',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '检查和修复缓存问题',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Colors.red[600],
            ),
            title: const Text('检查缓存状态'),
            subtitle: const Text('查看当前缓存数据状态'),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              await CacheDebugTool.printDebugInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('调试信息已输出到控制台'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.refresh,
              color: Colors.red[600],
            ),
            title: const Text('强制重新加载缓存'),
            subtitle: const Text('重新从存储加载缓存数据'),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('正在重新加载缓存...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              final result = await CacheDebugTool.forceReloadCache();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['success'] 
                      ? '缓存重新加载成功，共 ${result['lessons_count']} 个课程'
                      : '缓存重新加载失败: ${result['error']}'
                  ),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.sync_alt,
              color: Colors.red[600],
            ),
            title: const Text('刷新界面Provider'),
            subtitle: const Text('强制刷新课程列表和进度显示'),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              ProviderRefreshTool.showProviderStatusDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSourceSection() {
    final lessonManager = LessonManagerService.instance;
    final currentSource = lessonManager.currentSource;
    
    String sourceText;
    IconData sourceIcon;
    Color sourceColor;
    
    switch (currentSource) {
      case LessonSource.local:
        sourceText = '本地数据';
        sourceIcon = Icons.phone_android;
        sourceColor = Colors.green;
        break;
      case LessonSource.remote:
        sourceText = '远程数据';
        sourceIcon = Icons.cloud;
        sourceColor = Colors.blue;
        break;
      case LessonSource.mixed:
        sourceText = '智能混合';
        sourceIcon = Icons.sync;
        sourceColor = Colors.purple;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.source,
                    color: Colors.purple[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '课程数据源',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '本地/远程数据管理',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              sourceIcon,
              color: sourceColor,
            ),
            title: const Text('数据源管理'),
            subtitle: Text(
              '当前: $sourceText',
              style: TextStyle(
                color: sourceColor,
                fontSize: 12,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LessonSourcePage(),
                ),
              );
              // 返回后刷新状态
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupabaseSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud,
                    color: Colors.indigo[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '云端同步',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Supabase数据同步',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              SupabaseService.instance.isInitialized ? Icons.cloud_done : Icons.cloud_off,
              color: SupabaseService.instance.isInitialized ? Colors.green : Colors.grey,
            ),
            title: const Text('Supabase配置'),
            subtitle: Text(
              SupabaseService.instance.isInitialized ? '已连接云端数据库' : '点击配置云端同步',
              style: TextStyle(
                color: SupabaseService.instance.isInitialized ? Colors.green[600] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // 关闭drawer
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupabaseConfigPage(),
                ),
              );
              if (result == true) {
                // 配置成功后刷新状态
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习进度',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '当前学习状态',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '📖 当前课程: 第${defaultLessons[currentLessonIndex].lesson}课',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '📚 总进度: ${currentLessonIndex + 1}/${defaultLessons.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentLessonIndex + 1) / defaultLessons.length,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.list,
                    color: Colors.green[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '课程列表',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '选择要学习的课程',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...defaultLessons.asMap().entries.map((entry) {
            final index = entry.key;
            final lesson = entry.value;
            final isSelected = index == currentLessonIndex;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                child: Text(
                  '${lesson.lesson}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
              subtitle: Text(
                '${lesson.vocabulary.length}个生词 • ${lesson.questions.length}道练习题',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedTileColor: Colors.blue[50],
              onTap: () {
                setState(() {
                  currentLessonIndex = index;
                });
                _saveProgress(); // 保存进度
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLessonSelector() {
    final currentLesson = defaultLessons[currentLessonIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          IconButton(
            onPressed: currentLessonIndex > 0
                ? () {
                    setState(() => currentLessonIndex--);
                    _saveProgress();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: currentLessonIndex > 0 ? Colors.blue : Colors.grey[300],
              foregroundColor: currentLessonIndex > 0 ? Colors.white : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '第${currentLesson.lesson}课: ${currentLesson.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentLessonIndex + 1} / ${defaultLessons.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: currentLessonIndex < defaultLessons.length - 1
                ? () {
                    setState(() => currentLessonIndex++);
                    _saveProgress();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: currentLessonIndex < defaultLessons.length - 1 ? Colors.blue : Colors.grey[300],
              foregroundColor: currentLessonIndex < defaultLessons.length - 1 ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于应用'),
        content: const Text(
          '英语阅读理解学习平台\n\n'
          '这是一个专为提升英语阅读能力而设计的学习应用。\n\n'
          '功能特色：\n'
          '• 丰富的阅读材料\n'
          '• 词汇学习与高亮\n'
          '• 重点句子解析\n'
          '• 理解练习题\n'
          '• 个性化阅读设置\n'
          '• 语音朗读功能\n'
          '• 学习进度跟踪\n\n'
          '适合各个水平的英语学习者使用。',
        ),
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

// 阅读设置组件
class ReadingSettings extends StatefulWidget {
  final ReadingPreferences preferences;
  final Function(ReadingPreferences) onPreferencesChange;

  const ReadingSettings({
    super.key,
    required this.preferences,
    required this.onPreferencesChange,
  });

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.indigo[600],
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '阅读设置',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '自定义阅读体验',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFontSizeSettings(),
                  const SizedBox(height: 24),
                  _buildFontFamilySettings(),
                  const SizedBox(height: 24),
                  _buildVocabularyHighlightSettings(),
                  const SizedBox(height: 24),
                  _buildPreview(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFontSizeSettings() {
    final fontSizes = [
      {'label': '小', 'value': 14},
      {'label': '中', 'value': 16},
      {'label': '大', 'value': 18},
      {'label': '特大', 'value': 20},
      {'label': '超大', 'value': 24},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.text_fields, size: 16, color: Colors.black54),
            SizedBox(width: 8),
            Text(
              '字体大小',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: fontSizes.map((size) {
            final isSelected = widget.preferences.fontSize == size['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => widget.onPreferencesChange(
                    widget.preferences.copyWith(fontSize: size['value'] as int),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.indigo : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      size['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '当前: ${widget.preferences.fontSize}px',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFontFamilySettings() {
    final fontFamilies = [
      {'label': 'Roboto', 'value': 'Roboto'},
      {'label': 'Times', 'value': 'Times'},
      {'label': 'Arial', 'value': 'Arial'},
      {'label': 'Georgia', 'value': 'Georgia'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.font_download, size: 16, color: Colors.black54),
            SizedBox(width: 8),
            Text(
              '字体样式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fontFamilies.map((font) {
            final isSelected = widget.preferences.fontFamily == font['value'];
            return InkWell(
              onTap: () => widget.onPreferencesChange(
                widget.preferences.copyWith(fontFamily: font['value'] as String),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  font['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    fontFamily: font['value'] as String,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVocabularyHighlightSettings() {
    return Row(
      children: [
        Icon(
          widget.preferences.showVocabularyHighlight ? Icons.visibility : Icons.visibility_off,
          size: 16,
          color: Colors.black54,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '词汇高亮显示',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Switch(
          value: widget.preferences.showVocabularyHighlight,
          onChanged: (value) => widget.onPreferencesChange(
            widget.preferences.copyWith(showVocabularyHighlight: value),
          ),
          activeColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '预览效果：',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: widget.preferences.fontSize.toDouble(),
                color: Colors.black87,
                height: 1.5,
                fontFamily: widget.preferences.fontFamilyStyle,
              ),
              children: [
                const TextSpan(text: 'Sally wants a '),
                TextSpan(
                  text: 'dog',
                  style: TextStyle(
                    backgroundColor: widget.preferences.showVocabularyHighlight
                        ? Colors.yellow[200]
                        : null,
                    fontWeight: widget.preferences.showVocabularyHighlight
                        ? FontWeight.bold
                        : null,
                  ),
                ),
                const TextSpan(text: '. Can I have a dog? Sally asks mom and dad.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '大小: ${widget.preferences.fontSize}px | 字体: ${widget.preferences.fontFamily} | 高亮: ${widget.preferences.showVocabularyHighlight ? '开启' : '关闭'}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// 课程内容组件
class LessonContent extends StatefulWidget {
  final Lesson lesson;
  final ReadingPreferences readingPreferences;
  final TTSService ttsService;
  final ProgressService progressService;
  final bool showChrome;
  final ValueChanged<bool>? onChromeVisibilityChange;

  const LessonContent({
    super.key,
    required this.lesson,
    required this.readingPreferences,
    required this.ttsService,
    required this.progressService,
    this.showChrome = true,
    this.onChromeVisibilityChange,
  });

  @override
  State<LessonContent> createState() => _LessonContentState();
}

class _LessonContentState extends State<LessonContent> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, String> selectedAnswers = {};
  bool showResults = false;
  int score = 0;
  Set<String> highlightedWords = {};
  late ScrollController _scrollController;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateHighlightedWords();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(LessonContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readingPreferences.showVocabularyHighlight != 
        widget.readingPreferences.showVocabularyHighlight) {
      _updateHighlightedWords();
    }
    if (oldWidget.lesson.lesson != widget.lesson.lesson) {
      // 切换课程时重置状态
      selectedAnswers.clear();
      showResults = false;
      score = 0;
      _updateHighlightedWords();
    }
  }

  void _updateHighlightedWords() {
    if (widget.readingPreferences.showVocabularyHighlight) {
      highlightedWords = widget.lesson.vocabulary.map((v) => v.word.toLowerCase()).toSet();
    } else {
      highlightedWords.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.ttsService.stop();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final current = _scrollController.position.pixels;
    final direction = current > _lastOffset ? ScrollDirection.reverse : ScrollDirection.forward;
    _lastOffset = current;
    if (widget.onChromeVisibilityChange == null) return;
    // 仅在词汇/句子/练习题三个页签里响应（索引1/2/3）
    if (_tabController.index == 1 || _tabController.index == 2 || _tabController.index == 3) {
      if (direction == ScrollDirection.reverse && widget.showChrome) {
        widget.onChromeVisibilityChange!(false);
      } else if (direction == ScrollDirection.forward && !widget.showChrome) {
        widget.onChromeVisibilityChange!(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: widget.showChrome
              ? Container(
                  key: const ValueKey('tabs-visible'),
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
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.book), text: '阅读故事'),
                      Tab(icon: Icon(Icons.visibility), text: '词汇学习'),
                      Tab(icon: Icon(Icons.chat_bubble), text: '重点句子'),
                      Tab(icon: Icon(Icons.quiz), text: '练习题'),
                    ],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('tabs-hidden')),
        ),
        SizedBox(height: widget.showChrome ? 16 : 8),
        Expanded(
          child: Stack(
            children: [
              Container(
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStoryTab(),
                    _buildVocabularyTab(scrollController: _scrollController),
                    _buildSentencesTab(scrollController: _scrollController),
                    _buildQuizTab(scrollController: _scrollController),
                  ],
                ),
              ),
              if (_tabController.index == 0)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _showFullScreenReading,
                    backgroundColor: Colors.black.withOpacity(0.75),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.fullscreen),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建故事阅读标签页
  Widget _buildStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                '故事阅读',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _speakFullStory(),
                icon: Icon(
                  widget.ttsService.isSpeakingId('full_story') 
                    ? Icons.stop_circle 
                    : Icons.play_circle,
                  color: Colors.blue,
                ),
                tooltip: '朗读全文',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildClickableContent(widget.lesson.content),
          if (widget.readingPreferences.showVocabularyHighlight) ...[
            const SizedBox(height: 24),
            _buildVocabularyHighlightSection(),
          ] else ...[
            const SizedBox(height: 24),
            _buildHighlightDisabledSection(),
          ],
        ],
      ),
    );
  }

  void _showFullScreenReading() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fullscreen',
      barrierColor: Colors.black26,
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Material(
            color: const Color(0xFFF5ECD8), // Sepia 背景
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // 标题行
                        Row(
                          children: [
                            const Icon(Icons.menu_book, color: Color(0xFF7A5C3E), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '全文阅读',
                                style: TextStyle(
                                  color: const Color(0xFF5C4B3B),
                                  fontSize: widget.readingPreferences.fontSize.toDouble() + 2,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: widget.readingPreferences.fontFamilyStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 正文
                        DefaultTextStyle(
                          style: TextStyle(
                            color: const Color(0xFF2A2A2A),
                            height: 1.7,
                            fontSize: widget.readingPreferences.fontSize.toDouble(),
                            fontFamily: widget.readingPreferences.fontFamilyStyle,
                          ),
                          child: _buildClickableContent(widget.lesson.content),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF7A5C3E),
                    foregroundColor: const Color(0xFFF5ECD8),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.fullscreen_exit),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  /// 构建可点击的文本内容
  Widget _buildClickableContent(String content) {
    final paragraphs = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) return const SizedBox(height: 8);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildClickableParagraph(paragraph),
        );
      }).toList(),
    );
  }

  /// 构建可点击的段落
  Widget _buildClickableParagraph(String paragraph) {
    final tokenReg = RegExp(r'(\s+|[.,!?;:"()[\]{}]|[^\s.,!?;:\"()\[\]{}]+)');
    final parts = tokenReg
        .allMatches(paragraph)
        .map((m) => m.group(0)!)
        .where((t) => t.isNotEmpty)
        .toList();
    final List<Widget> widgets = [];
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      if (part.isEmpty) continue;
      
      if (RegExp(r'^\s+$').hasMatch(part)) {
        // 空格部分
        widgets.add(Text(
          part,
          style: TextStyle(
            fontSize: widget.readingPreferences.fontSize.toDouble(),
            color: Colors.black87,
            height: 1.6,
            fontFamily: widget.readingPreferences.fontFamilyStyle,
          ),
        ));
      } else if (RegExp(r'^[.,!?;:"()[\]{}]+$').hasMatch(part)) {
        // 标点符号部分
        widgets.add(Text(
          part,
          style: TextStyle(
            fontSize: widget.readingPreferences.fontSize.toDouble(),
            color: Colors.black87,
            height: 1.6,
            fontFamily: widget.readingPreferences.fontFamilyStyle,
          ),
        ));
      } else {
        // 单词部分
        final cleanWord = part.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
        final shouldHighlight = widget.readingPreferences.showVocabularyHighlight &&
            highlightedWords.contains(cleanWord);
        final isVocabWord = widget.lesson.vocabulary.any((vocab) => 
            vocab.word.toLowerCase() == cleanWord);
        
        widgets.add(GestureDetector(
          onTap: () => _speakWord(part),
          child: Container(
            decoration: BoxDecoration(
              color: shouldHighlight ? Colors.yellow[200] : null,
              borderRadius: BorderRadius.circular(2),
              border: isVocabWord ? Border(
                bottom: BorderSide(
                  color: Colors.blue[400]!,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ) : null,
            ),
            child: Text(
              part,
              style: TextStyle(
                fontSize: widget.readingPreferences.fontSize.toDouble(),
                fontWeight: shouldHighlight ? FontWeight.bold : null,
                color: Colors.black87,
                height: 1.6,
                fontFamily: widget.readingPreferences.fontFamilyStyle,
              ),
            ),
          ),
        ));
      }
      
      // 不再手动插入空格，由 token 本身携带空白；避免破坏标点。
    }
    
    return Wrap(
      children: widgets,
    );
  }

  /// 构建词汇高亮控制区域
  Widget _buildVocabularyHighlightSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                '点击词汇控制高亮显示',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.lesson.vocabulary.map((vocab) {
              final isHighlighted = highlightedWords.contains(vocab.word.toLowerCase());
              return InkWell(
                onTap: () => _toggleWordHighlight(vocab.word),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.yellow[200] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHighlighted ? Colors.yellow[600]! : Colors.blue[200]!,
                    ),
                  ),
                  child: Text(
                    vocab.word,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHighlighted ? Colors.yellow[800] : Colors.blue[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建高亮功能关闭提示区域
  Widget _buildHighlightDisabledSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                '词汇高亮已关闭',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '您可以在左侧侧边栏的"阅读设置"中开启词汇高亮功能',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建词汇学习标签页
  Widget _buildVocabularyTab({ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                '词汇学习',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.volume_up, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '语音朗读功能：点击 🔊 按钮可以朗读单词和释义，帮助您学习正确发音',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...widget.lesson.vocabulary.asMap().entries.map((entry) {
            final index = entry.key;
            final vocab = entry.value;
            return _buildVocabularyCard(vocab, index);
          }).toList(),
        ],
      ),
    );
  }

  /// 构建词汇卡片
  Widget _buildVocabularyCard(Vocabulary vocab, int index) {
    final vocabId = 'vocab-$index';
    final isPlaying = widget.ttsService.isSpeakingId(vocabId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFEBF8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vocab.word,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: widget.readingPreferences.fontFamilyStyle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vocab.meaning,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontFamily: widget.readingPreferences.fontFamilyStyle,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _speakVocabulary(vocab, vocabId),
                icon: Icon(
                  isPlaying ? Icons.stop_circle : Icons.play_circle,
                  color: isPlaying ? Colors.red : Colors.green,
                  size: 32,
                ),
                tooltip: '朗读单词和释义',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniSpeakButton('🔊 单词', () => widget.ttsService.speakWord(vocab.word, id: '$vocabId-word'), '$vocabId-word', Colors.blue),
                  const SizedBox(width: 4),
                  _buildMiniSpeakButton('🔊 释义', () => widget.ttsService.speak(vocab.meaning.split(';')[0], id: '$vocabId-meaning'), '$vocabId-meaning', Colors.purple),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建小型朗读按钮
  Widget _buildMiniSpeakButton(String text, VoidCallback onTap, String id, MaterialColor color) {
    final isPlaying = widget.ttsService.isSpeakingId(id);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPlaying ? color[500] : color[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isPlaying ? Colors.white : color[700],
          ),
        ),
      ),
    );
  }

  /// 构建重点句子标签页
  Widget _buildSentencesTab({ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                '重点句子解析',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.volume_up, color: Colors.purple[600], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '句子朗读功能：点击每个句子右侧的 🔊 按钮可以朗读英文句子，帮助您练习发音和语调',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...widget.lesson.sentences.asMap().entries.map((entry) {
            final index = entry.key;
            final sentence = entry.value;
            return _buildSentenceCard(sentence, index);
          }).toList(),
        ],
      ),
    );
  }

  /// 构建句子卡片
  Widget _buildSentenceCard(Sentence sentence, int index) {
    final sentenceId = 'sentence-$index';
    final isPlaying = widget.ttsService.isSpeakingId(sentenceId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFFDF2F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '"${sentence.text}"',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                    fontFamily: widget.readingPreferences.fontFamilyStyle,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.ttsService.speak(sentence.text, id: sentenceId),
                icon: Icon(
                  isPlaying ? Icons.stop_circle : Icons.play_circle,
                  color: isPlaying ? Colors.red : Colors.purple,
                  size: 28,
                ),
                tooltip: '朗读句子',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[100]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📝 解析：',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sentence.note,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontFamily: widget.readingPreferences.fontFamilyStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMiniSpeakButton('🔊 慢速', () => widget.ttsService.speakSentenceSlow(sentence.text, id: '$sentenceId-slow'), '$sentenceId-slow', Colors.indigo),
              const SizedBox(width: 8),
              _buildMiniSpeakButton('🔊 快速', () => widget.ttsService.speakSentenceFast(sentence.text, id: '$sentenceId-fast'), '$sentenceId-fast', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建练习题标签页
  Widget _buildQuizTab({ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                '练习题',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (showResults) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '得分: $score/${widget.lesson.questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _resetQuiz,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          ...widget.lesson.questions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final question = entry.value;
            return _buildQuestionCard(question, qIndex);
          }).toList(),
          if (!showResults) ...[
            const SizedBox(height: 24),
            _buildSubmitSection(),
          ],
        ],
      ),
    );
  }

  /// 构建问题卡片
  Widget _buildQuestionCard(Question question, int qIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.q,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: widget.readingPreferences.fontFamilyStyle,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.ttsService.speak(question.q, id: 'question-$qIndex'),
                icon: Icon(
                  widget.ttsService.isSpeakingId('question-$qIndex') ? Icons.stop_circle : Icons.play_circle,
                  color: Colors.orange,
                ),
                tooltip: '朗读题目',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...['A', 'B', 'C', 'D'].map((key) {
            final value = question.options.getOption(key);
            if (value == null) return const SizedBox.shrink();
            
            final isSelected = selectedAnswers[qIndex] == key;
            final isCorrect = question.answer == key;
            final isWrong = showResults && isSelected && !isCorrect;
            final shouldShowCorrect = showResults && isCorrect;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: showResults ? null : () => _handleAnswerSelect(qIndex, key),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isWrong
                        ? Colors.red[50]
                        : shouldShowCorrect
                        ? Colors.green[50]
                        : isSelected
                        ? Colors.blue[50]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWrong
                          ? Colors.red[400]!
                          : shouldShowCorrect
                          ? Colors.green[400]!
                          : isSelected
                          ? Colors.blue[400]!
                          : Colors.grey[200]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$key. $value',
                          style: TextStyle(
                            fontSize: 20,
                            color: isWrong
                                ? Colors.red[700]
                                : shouldShowCorrect
                                ? Colors.green[700]
                                : isSelected
                                ? Colors.blue[700]
                                : Colors.black87,
                            fontFamily: widget.readingPreferences.fontFamilyStyle,
                          ),
                        ),
                      ),
                      if (showResults) ...[
                        if (isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        else if (isWrong)
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建提交答案区域
  Widget _buildSubmitSection() {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: selectedAnswers.length == widget.lesson.questions.length
                ? _submitQuiz
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '提交答案',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已完成 ${selectedAnswers.length}/${widget.lesson.questions.length} 题',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  void _speakFullStory() {
    widget.ttsService.speak(widget.lesson.content, id: 'full_story');
  }

  void _speakWord(String word) {
    widget.ttsService.speakWord(word);
  }

  void _speakVocabulary(Vocabulary vocab, String id) {
    widget.ttsService.speak('${vocab.word}. ${vocab.meaning}', id: id);
  }

  void _toggleWordHighlight(String word) {
    setState(() {
      final lowerWord = word.toLowerCase();
      if (highlightedWords.contains(lowerWord)) {
        highlightedWords.remove(lowerWord);
      } else {
        highlightedWords.add(lowerWord);
      }
    });
  }

  void _handleAnswerSelect(int questionIndex, String answer) {
    if (!showResults) {
      setState(() {
        selectedAnswers[questionIndex] = answer;
      });
    }
  }

  void _submitQuiz() async {
    final correctCount = widget.lesson.questions.asMap().entries.fold<int>(
      0,
      (count, entry) {
        final index = entry.key;
        final question = entry.value;
        return selectedAnswers[index] == question.answer ? count + 1 : count;
      },
    );
    
    setState(() {
      score = correctCount;
      showResults = true;
    });

    // 保存分数到进度服务
    await widget.progressService.updateLessonScore(
      widget.lesson.lesson.toString(), 
      correctCount
    );

    // 显示结果对话框
    if (mounted) {
      _showResultDialog(correctCount);
    }
  }

  void _showResultDialog(int correctCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测试完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              correctCount >= widget.lesson.questions.length * 0.8
                  ? Icons.emoji_events
                  : correctCount >= widget.lesson.questions.length * 0.6
                  ? Icons.thumb_up
                  : Icons.school,
              size: 48,
              color: correctCount >= widget.lesson.questions.length * 0.8
                  ? Colors.amber
                  : correctCount >= widget.lesson.questions.length * 0.6
                  ? Colors.green
                  : Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '您的得分：$correctCount/${widget.lesson.questions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '正确率：${(correctCount / widget.lesson.questions.length * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              correctCount >= widget.lesson.questions.length * 0.8
                  ? '🎉 太棒了！您掌握得很好！'
                  : correctCount >= widget.lesson.questions.length * 0.6
                  ? '👍 不错！继续加油！'
                  : '📚 还需要多练习哦！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
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
  }

  void _resetQuiz() {
    setState(() {
      selectedAnswers.clear();
      showResults = false;
      score = 0;
    });
  }
}
