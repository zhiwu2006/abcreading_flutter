import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/progress_provider.dart';
import '../../domain/entities/lesson_entity.dart';

/// 课程列表组件
class LessonListWidget extends StatefulWidget {
  const LessonListWidget({super.key});

  @override
  State<LessonListWidget> createState() => _LessonListWidgetState();
}

class _LessonListWidgetState extends State<LessonListWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        
        // 课程列表
        Expanded(
          child: _buildLessonList(),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索课程...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Consumer<LessonProvider>(
            builder: (context, lessonProvider, child) {
              if (lessonProvider.searchQuery.isNotEmpty) {
                return IconButton(
                  onPressed: () {
                    _searchController.clear();
                    lessonProvider.clearSearch();
                  },
                  icon: const Icon(Icons.clear),
                );
              }
              return null;
            },
          ),
        ),
        onChanged: (query) {
          context.read<LessonProvider>().searchLessons(query);
        },
      ),
    );
  }

  /// 构建课程列表
  Widget _buildLessonList() {
    return Consumer2<LessonProvider, ProgressProvider>(
      builder: (context, lessonProvider, progressProvider, child) {
        if (lessonProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (lessonProvider.hasError) {
          return _buildErrorWidget(lessonProvider.error);
        }

        if (!lessonProvider.hasLessons) {
          return _buildEmptyWidget();
        }

        final lessons = lessonProvider.filteredLessons;
        
        return RefreshIndicator(
          onRefresh: () => lessonProvider.refresh(),
          child: ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final isCurrentLesson = progressProvider.currentLessonNumber == lesson.lesson;
              
              return _buildLessonCard(lesson, isCurrentLesson, progressProvider);
            },
          ),
        );
      },
    );
  }

  /// 构建课程卡片
  Widget _buildLessonCard(
    LessonEntity lesson,
    bool isCurrentLesson,
    ProgressProvider progressProvider,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isCurrentLesson ? 4 : 2,
      child: InkWell(
        onTap: () => _selectLesson(lesson, progressProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCurrentLesson
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 课程标题和编号
              Row(
                children: [
                  // 课程编号
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrentLesson
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${lesson.lesson}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 课程标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentLesson
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 课程统计信息
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.book,
                              '${lesson.vocabulary.length} 生词',
                              theme.colorScheme.secondary,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            _buildStatChip(
                              Icons.quiz,
                              '${lesson.questions.length} 问题',
                              theme.colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 当前课程标识
                  if (isCurrentLesson)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '当前',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 课程内容预览
              Text(
                lesson.content.length > 100
                    ? '${lesson.content.substring(0, 100)}...'
                    : lesson.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 难度标识
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(lesson.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getDifficultyColor(lesson.difficulty),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lesson.difficulty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getDifficultyColor(lesson.difficulty),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // 预计阅读时间
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '约 ${lesson.estimatedReadingTime} 分钟',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计信息芯片
  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<LessonProvider>().refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态组件
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无课程',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '请稍后再试或联系管理员',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<LessonProvider>().refresh();
            },
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  /// 选择课程
  Future<void> _selectLesson(
    LessonEntity lesson,
    ProgressProvider progressProvider,
  ) async {
    try {
      // 更新进度
      final success = await progressProvider.jumpToLesson(
        targetLessonIndex: lesson.lesson - 1,
        targetLessonNumber: lesson.lesson,
        totalLessons: context.read<LessonProvider>().totalLessons,
      );

      if (success) {
        // 设置当前课程
        context.read<LessonProvider>().setCurrentLesson(lesson);

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到第${lesson.lesson}课'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        throw Exception('切换课程失败');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('切换课程失败: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// 获取难度颜色
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '简单':
        return Colors.green;
      case '中等':
        return Colors.orange;
      case '困难':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}