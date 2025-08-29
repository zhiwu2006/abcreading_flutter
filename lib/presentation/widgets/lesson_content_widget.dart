import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/preferences_provider.dart';
import '../../domain/entities/lesson_entity.dart';

/// 课程内容组件
class LessonContentWidget extends StatefulWidget {
  const LessonContentWidget({super.key});

  @override
  State<LessonContentWidget> createState() => _LessonContentWidgetState();
}

class _LessonContentWidgetState extends State<LessonContentWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, lessonProvider, child) {
        final currentLesson = lessonProvider.currentLesson;
        
        if (currentLesson == null) {
          return _buildNoLessonWidget();
        }

        return Column(
          children: [
            // 课程标题栏
            _buildLessonHeader(currentLesson),
            
            // 标签栏
            _buildTabBar(),
            
            // 标签内容
            Expanded(
              child: _buildTabBarView(currentLesson),
            ),
          ],
        );
      },
    );
  }

  /// 构建课程标题栏
  Widget _buildLessonHeader(LessonEntity lesson) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 课程编号
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '${lesson.lesson}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 课程信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.schedule,
                      '约 ${lesson.estimatedReadingTime} 分钟',
                      theme.colorScheme.secondary,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    _buildInfoChip(
                      Icons.signal_cellular_alt,
                      lesson.difficulty,
                      _getDifficultyColor(lesson.difficulty),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.article), text: '课文'),
        Tab(icon: Icon(Icons.book), text: '生词'),
        Tab(icon: Icon(Icons.format_quote), text: '句型'),
        Tab(icon: Icon(Icons.quiz), text: '练习'),
      ],
    );
  }

  /// 构建标签内容
  Widget _buildTabBarView(LessonEntity lesson) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentTab(lesson),
        _buildVocabularyTab(lesson),
        _buildSentencesTab(lesson),
        _buildQuestionsTab(lesson),
      ],
    );
  }

  /// 构建课文标签页
  Widget _buildContentTab(LessonEntity lesson) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        final preferences = preferencesProvider.preferences;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                lesson.content,
                style: TextStyle(
                  fontSize: preferences?.fontSize ?? 24.0,
                  fontFamily: preferences?.fontFamilyDisplay ?? 'Times New Roman',
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建生词标签页
  Widget _buildVocabularyTab(LessonEntity lesson) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        final showHighlight = preferencesProvider.showVocabularyHighlight;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lesson.vocabulary.length,
          itemBuilder: (context, index) {
            final vocab = lesson.vocabulary[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: showHighlight
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  vocab.word,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  vocab.meaning,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: showHighlight
                    ? Icon(
                        Icons.highlight,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  /// 构建句型标签页
  Widget _buildSentencesTab(LessonEntity lesson) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lesson.sentences.length,
      itemBuilder: (context, index) {
        final sentence = lesson.sentences[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 句子编号
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '句型 ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 句子内容
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    sentence.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 句型分析
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sentence.note,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建练习标签页
  Widget _buildQuestionsTab(LessonEntity lesson) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lesson.questions.length,
      itemBuilder: (context, index) {
        final question = lesson.questions[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 问题编号和内容
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 选项
                ...question.options.optionsMap.entries.map((entry) {
                  final isCorrect = entry.key == question.answer;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        
                        if (isCorrect)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建无课程组件
  Widget _buildNoLessonWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '请选择一个课程',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '从课程列表中选择一个课程开始学习',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Consumer<ProgressProvider>(
            builder: (context, progressProvider, child) {
              if (progressProvider.hasProgress) {
                return ElevatedButton.icon(
                  onPressed: () => _loadCurrentLesson(),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('继续学习第${progressProvider.currentLessonNumber}课'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// 加载当前课程
  Future<void> _loadCurrentLesson() async {
    final progressProvider = context.read<ProgressProvider>();
    final lessonProvider = context.read<LessonProvider>();
    
    try {
      final currentLesson = await lessonProvider.getLessonById(
        progressProvider.currentLessonNumber,
      );
      
      if (currentLesson != null) {
        lessonProvider.setCurrentLesson(currentLesson);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载课程失败: $error'),
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