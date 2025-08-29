import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/preferences_provider.dart';
import '../widgets/lesson_list_widget.dart';
import '../widgets/lesson_content_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/settings_drawer.dart';

/// 主页面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: const SettingsDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('英语阅读理解学习平台'),
      centerTitle: true,
      elevation: 0,
      actions: [
        // 同步按钮
        Consumer<LessonProvider>(
          builder: (context, lessonProvider, child) {
            return IconButton(
              onPressed: lessonProvider.isSyncing ? null : () => _syncData(),
              icon: lessonProvider.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync),
              tooltip: '同步数据',
            );
          },
        ),
        
        // 设置按钮
        IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.settings),
          tooltip: '设置',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.list),
            text: '课程列表',
          ),
          Tab(
            icon: Icon(Icons.book),
            text: '当前课程',
          ),
        ],
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    return Column(
      children: [
        // 进度指示器
        const ProgressIndicatorWidget(),
        
        // 标签页内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 课程列表页
              const LessonListWidget(),
              
              // 当前课程页
              const LessonContentWidget(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建浮动操作按钮
  Widget? _buildFloatingActionButton() {
    return Consumer2<ProgressProvider, LessonProvider>(
      builder: (context, progressProvider, lessonProvider, child) {
        if (_tabController.index == 1 && progressProvider.hasProgress) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上一课按钮
              if (progressProvider.canGoPrevious())
                FloatingActionButton(
                  heroTag: 'previous',
                  mini: true,
                  onPressed: () => _previousLesson(),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.navigate_before),
                ),
              
              if (progressProvider.canGoPrevious() && progressProvider.canGoNext())
                const SizedBox(height: 8),
              
              // 下一课按钮
              if (progressProvider.canGoNext())
                FloatingActionButton(
                  heroTag: 'next',
                  onPressed: () => _nextLesson(),
                  child: const Icon(Icons.navigate_next),
                ),
            ],
          );
        }
        return null;
      },
    );
  }

  /// 同步数据
  Future<void> _syncData() async {
    final lessonProvider = context.read<LessonProvider>();
    final progressProvider = context.read<ProgressProvider>();

    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('正在同步数据...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // 同步课程数据
      final syncSuccess = await lessonProvider.syncLessons();
      
      if (syncSuccess) {
        // 更新进度
        await progressProvider.refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('数据同步成功'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('同步失败');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('同步失败: $error')),
            ],
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: () => _syncData(),
          ),
        ),
      );
    }
  }

  /// 上一课
  Future<void> _previousLesson() async {
    final progressProvider = context.read<ProgressProvider>();
    final lessonProvider = context.read<LessonProvider>();

    try {
      final success = await progressProvider.previousLesson();
      
      if (success) {
        // 更新当前课程
        final currentLesson = await lessonProvider.getLessonById(
          progressProvider.currentLessonNumber,
        );
        
        if (currentLesson != null) {
          lessonProvider.setCurrentLesson(currentLesson);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到第${progressProvider.currentLessonNumber}课'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('切换课程失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 下一课
  Future<void> _nextLesson() async {
    final progressProvider = context.read<ProgressProvider>();
    final lessonProvider = context.read<LessonProvider>();

    try {
      final success = await progressProvider.nextLesson();
      
      if (success) {
        // 更新当前课程
        final currentLesson = await lessonProvider.getLessonById(
          progressProvider.currentLessonNumber,
        );
        
        if (currentLesson != null) {
          lessonProvider.setCurrentLesson(currentLesson);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到第${progressProvider.currentLessonNumber}课'),
            duration: const Duration(seconds: 1),
          ),
        );
        
        // 如果完成了所有课程，显示祝贺信息
        if (progressProvider.isCompleted) {
          _showCompletionDialog();
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('切换课程失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示完成对话框
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('恭喜完成！'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉 恭喜您完成了所有课程的学习！'),
            SizedBox(height: 16),
            Text('您已经掌握了所有的英语阅读理解内容。继续保持学习的热情！'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续复习'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetProgress();
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  /// 重置进度
  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要重置学习进度吗？这将清除您的所有学习记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final progressProvider = context.read<ProgressProvider>();
      final lessonProvider = context.read<LessonProvider>();

      try {
        final success = await progressProvider.resetProgress(lessonProvider.totalLessons);
        
        if (success) {
          // 重置当前课程
          final firstLesson = await lessonProvider.getLessonById(1);
          if (firstLesson != null) {
            lessonProvider.setCurrentLesson(firstLesson);
          }
          
          // 切换到第一个标签页
          _tabController.animateTo(0);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(width: 16),
                  Text('学习进度已重置'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重置失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}