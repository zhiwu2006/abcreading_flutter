import 'package:flutter/material.dart';
import '../../services/lesson_manager_service.dart';
import '../../services/supabase_service.dart';

class LessonSourcePage extends StatefulWidget {
  const LessonSourcePage({super.key});

  @override
  State<LessonSourcePage> createState() => _LessonSourcePageState();
}

class _LessonSourcePageState extends State<LessonSourcePage> {
  final LessonManagerService _lessonManager = LessonManagerService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  bool _isLoading = false;
  Map<String, dynamic>? _lessonStats;

  @override
  void initState() {
    super.initState();
    _loadLessonStats();
  }

  Future<void> _loadLessonStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _lessonManager.getLessonStats();
      setState(() {
        _lessonStats = stats;
      });
    } catch (e) {
      print('加载课程统计失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncRemoteToLocal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _lessonManager.syncRemoteToLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ 远程数据同步到本地成功' : '❌ 同步失败，请重试'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      if (success) {
        await _loadLessonStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 同步失败: $e'),
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

  Future<void> _uploadLocalToRemote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _lessonManager.uploadLocalToRemote();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ 本地数据上传到远程成功' : '❌ 上传失败，请重试'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      if (success) {
        await _loadLessonStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 上传失败: $e'),
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _lessonManager.refreshAll();
      await _loadLessonStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 数据刷新完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
        title: const Text('课程数据源管理'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在处理数据...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentSourceCard(),
                  const SizedBox(height: 16),
                  _buildDataSourceSelector(),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildSyncSection(),
                  const SizedBox(height: 16),
                  _buildHelpSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSourceCard() {
    if (_lessonStats == null) return const SizedBox.shrink();

    final currentSource = _lessonStats!['current_source'] as String;
    final isConnected = _lessonStats!['supabase_connected'] as bool;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSourceIcon(currentSource),
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '当前数据源: ${_getSourceName(currentSource)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getSourceDescription(currentSource),
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
          if (!isConnected && currentSource != 'local') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '注意：Supabase未连接，将自动回退到本地数据',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSourceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择数据源',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSourceOption(
            LessonSource.local,
            '本地数据',
            '使用应用内置的课程数据',
            Icons.phone_android,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSourceOption(
            LessonSource.remote,
            '远程数据',
            '使用Supabase云端数据库中的课程',
            Icons.cloud,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSourceOption(
            LessonSource.mixed,
            '智能混合',
            '优先使用远程数据，连接失败时自动切换到本地',
            Icons.sync,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption(
    LessonSource source,
    String title,
    String description,
    IconData icon,
    MaterialColor color,
  ) {
    final isSelected = _lessonManager.currentSource == source;
    final isEnabled = source == LessonSource.local || _supabaseService.isInitialized;

    return InkWell(
      onTap: isEnabled
          ? () {
              _lessonManager.setSource(source);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ 已切换到: $title'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color[300]! : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? color[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color[600] : Colors.grey[500],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color[600],
                size: 20,
              ),
            if (!isEnabled)
              Icon(
                Icons.lock,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_lessonStats == null) return const SizedBox.shrink();

    final localCount = _lessonStats!['local_count'] as int;
    final remoteCount = _lessonStats!['remote_count'] as int;
    final lastSyncTime = _lessonStats!['last_sync_time'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text(
                '数据统计',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '本地课程',
                  localCount.toString(),
                  Icons.phone_android,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '远程课程',
                  remoteCount.toString(),
                  Icons.cloud,
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (lastSyncTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.sync, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '最后同步: ${_formatDateTime(lastSyncTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color[600], size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection() {
    final isConnected = _lessonStats?['supabase_connected'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_alt, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '数据同步',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Supabase未连接，无法进行数据同步',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isConnected && !_isLoading ? _syncRemoteToLocal : null,
                  icon: const Icon(Icons.download),
                  label: const Text('远程→本地'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isConnected && !_isLoading ? _uploadLocalToRemote : null,
                  icon: const Icon(Icons.upload),
                  label: const Text('本地→远程'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '使用说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• 本地数据：使用应用内置课程，无需网络连接\n'
            '• 远程数据：从Supabase云端加载课程，需要网络连接\n'
            '• 智能混合：自动选择最佳数据源，推荐使用\n'
            '• 远程→本地：将云端课程下载到本地缓存\n'
            '• 本地→远程：将本地课程上传到云端数据库',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'local':
        return Icons.phone_android;
      case 'remote':
        return Icons.cloud;
      case 'mixed':
        return Icons.sync;
      default:
        return Icons.help_outline;
    }
  }

  String _getSourceName(String source) {
    switch (source) {
      case 'local':
        return '本地数据';
      case 'remote':
        return '远程数据';
      case 'mixed':
        return '智能混合';
      default:
        return '未知';
    }
  }

  String _getSourceDescription(String source) {
    switch (source) {
      case 'local':
        return '使用应用内置的课程数据，无需网络连接';
      case 'remote':
        return '从Supabase云端数据库加载课程';
      case 'mixed':
        return '优先使用远程数据，连接失败时自动切换到本地';
      default:
        return '';
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
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
    } catch (e) {
      return '未知';
    }
  }
}