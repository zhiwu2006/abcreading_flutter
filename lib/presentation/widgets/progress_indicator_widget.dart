import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';

/// 进度指示器组件
class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        if (!progressProvider.hasProgress) {
          return const SizedBox.shrink();
        }

        final progress = progressProvider.progress!;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              // 进度条和百分比
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 进度描述
                        Text(
                          progress.progressDescription,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // 进度条
                        LinearProgressIndicator(
                          value: progress.progressPercentage,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progress.progressPercentage, theme),
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 百分比显示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getProgressColor(progress.progressPercentage, theme)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getProgressColor(progress.progressPercentage, theme),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(progress.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _getProgressColor(progress.progressPercentage, theme),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 详细信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 当前课程信息
                  _buildInfoItem(
                    icon: Icons.book,
                    label: '当前课程',
                    value: '第 ${progress.currentLessonNumber} 课',
                    color: theme.colorScheme.primary,
                  ),
                  
                  // 剩余课程
                  _buildInfoItem(
                    icon: Icons.pending_actions,
                    label: '剩余课程',
                    value: '${progress.remainingLessons} 课',
                    color: theme.colorScheme.secondary,
                  ),
                  
                  // 学习状态
                  _buildInfoItem(
                    icon: _getStatusIcon(progress.progressStatus),
                    label: '学习状态',
                    value: progress.progressStatus,
                    color: _getStatusColor(progress.progressStatus, theme),
                  ),
                ],
              ),
              
              // 完成状态特殊显示
              if (progress.isCompleted)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎉 恭喜！您已完成所有课程的学习！',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 获取进度颜色
  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) {
      return theme.colorScheme.secondary; // 完成 - 绿色
    } else if (progress >= 0.8) {
      return theme.colorScheme.tertiary; // 接近完成 - 橙色
    } else if (progress >= 0.5) {
      return theme.colorScheme.primary; // 进行中 - 蓝色
    } else {
      return theme.colorScheme.outline; // 刚开始 - 灰色
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon(String status) {
    switch (status) {
      case '已完成':
        return Icons.check_circle;
      case '学习中':
        return Icons.play_circle;
      case '未开始':
        return Icons.radio_button_unchecked;
      default:
        return Icons.help_outline;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case '已完成':
        return theme.colorScheme.secondary;
      case '学习中':
        return theme.colorScheme.primary;
      case '未开始':
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.outline;
    }
  }
}