import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/lesson_provider.dart';

/// 设置抽屉组件
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Column(
        children: [
          // 抽屉头部
          _buildDrawerHeader(theme),
          
          // 设置内容
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 阅读设置
                _buildSectionTitle('阅读设置', Icons.settings),
                _buildFontSizeSettings(),
                _buildFontFamilySettings(),
                _buildVocabularyHighlightSettings(),
                
                const Divider(),
                
                // 学习进度
                _buildSectionTitle('学习进度', Icons.trending_up),
                _buildProgressInfo(),
                _buildProgressActions(),
                
                const Divider(),
                
                // 数据管理
                _buildSectionTitle('数据管理', Icons.storage),
                _buildDataActions(),
                
                const Divider(),
                
                // 应用信息
                _buildSectionTitle('应用信息', Icons.info),
                _buildAppInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建抽屉头部
  Widget _buildDrawerHeader(ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 应用图标和名称
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '英语阅读理解',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '学习平台',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // 版本信息
          Text(
            'v1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建字体大小设置
  Widget _buildFontSizeSettings() {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        final fontSize = preferencesProvider.fontSize;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('字体大小: ${fontSize.toInt()}px'),
                  Text(
                    preferencesProvider.preferences?.fontSizeDescription ?? '正常',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  IconButton(
                    onPressed: preferencesProvider.canDecreaseFontSize
                        ? () => preferencesProvider.decreaseFontSize()
                        : null,
                    icon: const Icon(Icons.remove),
                    tooltip: '减小字体',
                  ),
                  
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: preferencesProvider.minFontSize,
                      max: preferencesProvider.maxFontSize,
                      divisions: ((preferencesProvider.maxFontSize - preferencesProvider.minFontSize) / 
                                 preferencesProvider.fontSizeStep).round(),
                      onChanged: (value) {
                        preferencesProvider.updateFontSize(value);
                      },
                    ),
                  ),
                  
                  IconButton(
                    onPressed: preferencesProvider.canIncreaseFontSize
                        ? () => preferencesProvider.increaseFontSize()
                        : null,
                    icon: const Icon(Icons.add),
                    tooltip: '增大字体',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建字体类型设置
  Widget _buildFontFamilySettings() {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        final fontOptions = preferencesProvider.getFontOptions();
        final currentFont = preferencesProvider.fontFamily;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('字体类型'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: currentFont,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: fontOptions.map((font) {
                  return DropdownMenuItem<String>(
                    value: font['value'],
                    child: Text(font['display']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    preferencesProvider.updateFontFamily(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建生词高亮设置
  Widget _buildVocabularyHighlightSettings() {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        return SwitchListTile(
          title: const Text('生词高亮'),
          subtitle: const Text('在生词列表中高亮显示重要词汇'),
          value: preferencesProvider.showVocabularyHighlight,
          onChanged: (value) {
            preferencesProvider.toggleVocabularyHighlight(value);
          },
        );
      },
    );
  }

  /// 构建进度信息
  Widget _buildProgressInfo() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        if (!progressProvider.hasProgress) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无学习记录'),
          );
        }

        final progress = progressProvider.progress!;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.progressDescription,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.progressPercentage,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '剩余: ${progress.remainingLessons}课',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${(progress.progressPercentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建进度操作
  Widget _buildProgressActions() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重置进度'),
              subtitle: const Text('清除所有学习记录，重新开始'),
              onTap: () => _showResetProgressDialog(context, progressProvider),
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('跳转课程'),
              subtitle: const Text('跳转到指定课程'),
              onTap: () => _showJumpToLessonDialog(context, progressProvider),
            ),
          ],
        );
      },
    );
  }

  /// 构建数据操作
  Widget _buildDataActions() {
    return Consumer<LessonProvider>(
      builder: (context, lessonProvider, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('同步数据'),
              subtitle: const Text('从服务器同步最新课程数据'),
              trailing: lessonProvider.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: lessonProvider.isSyncing
                  ? null
                  : () => _syncData(context, lessonProvider),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('刷新数据'),
              subtitle: const Text('重新加载本地课程数据'),
              onTap: () => lessonProvider.refresh(),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出数据'),
              subtitle: const Text('导出学习数据到文件'),
              onTap: () => _exportData(context, lessonProvider),
            ),
          ],
        );
      },
    );
  }

  /// 构建应用信息
  Widget _buildAppInfo() {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('版本'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('帮助'),
          subtitle: const Text('查看使用说明'),
          onTap: () => _showHelpDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('反馈'),
          subtitle: const Text('提交问题或建议'),
          onTap: () => _showFeedbackDialog(context),
        ),
      ],
    );
  }

  /// 显示重置进度对话框
  void _showResetProgressDialog(BuildContext context, ProgressProvider progressProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置学习进度'),
        content: const Text('确定要重置学习进度吗？这将清除所有学习记录，无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final lessonProvider = context.read<LessonProvider>();
              await progressProvider.resetProgress(lessonProvider.totalLessons);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('学习进度已重置')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  /// 显示跳转课程对话框
  void _showJumpToLessonDialog(BuildContext context, ProgressProvider progressProvider) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到课程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请输入要跳转的课程编号 (1-${progressProvider.totalLessons})'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '课程编号',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lessonNumber = int.tryParse(controller.text);
              if (lessonNumber != null && 
                  lessonNumber >= 1 && 
                  lessonNumber <= progressProvider.totalLessons) {
                Navigator.of(context).pop();
                
                await progressProvider.jumpToLesson(
                  targetLessonIndex: lessonNumber - 1,
                  targetLessonNumber: lessonNumber,
                  totalLessons: progressProvider.totalLessons,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已跳转到第${lessonNumber}课')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的课程编号')),
                );
              }
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }

  /// 同步数据
  Future<void> _syncData(BuildContext context, LessonProvider lessonProvider) async {
    try {
      final success = await lessonProvider.syncLessons();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '数据同步成功' : '数据同步失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 导出数据
  Future<void> _exportData(BuildContext context, LessonProvider lessonProvider) async {
    try {
      final jsonString = await lessonProvider.exportLessonsToJson();
      
      if (jsonString != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导出成功')),
        );
        // 这里可以添加保存文件的逻辑
      } else {
        throw Exception('导出失败');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📚 课程学习', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 在课程列表中选择要学习的课程'),
              Text('• 阅读课文内容，学习生词和句型'),
              Text('• 完成练习题巩固知识'),
              SizedBox(height: 16),
              Text('⚙️ 个性化设置', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 调整字体大小和类型'),
              Text('• 开启或关闭生词高亮'),
              Text('• 查看和管理学习进度'),
              SizedBox(height: 16),
              Text('💾 数据管理', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 同步最新课程数据'),
              Text('• 导出学习记录'),
              Text('• 重置学习进度'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示反馈对话框
  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意见反馈'),
        content: const Text('如果您在使用过程中遇到问题或有改进建议，请通过以下方式联系我们：\n\n📧 邮箱: feedback@example.com\n💬 微信: EnglishLearning'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}