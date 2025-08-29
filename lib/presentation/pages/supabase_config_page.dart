import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';

class SupabaseConfigPage extends StatefulWidget {
  const SupabaseConfigPage({super.key});

  @override
  State<SupabaseConfigPage> createState() => _SupabaseConfigPageState();
}

class _SupabaseConfigPageState extends State<SupabaseConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
    _checkConnection();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('supabase_url') ?? '';
      _keyController.text = prefs.getString('supabase_key') ?? '';
    });
  }

  Future<void> _checkConnection() async {
    if (SupabaseService.instance.isInitialized) {
      final connected = await SupabaseService.instance.testConnection();
      setState(() {
        _isConnected = connected;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', _urlController.text.trim());
      await prefs.setString('supabase_key', _keyController.text.trim());

      // 重新初始化Supabase
      await SupabaseService.initialize(
        url: _urlController.text.trim(),
        anonKey: _keyController.text.trim(),
      );

      // 测试连接
      final connected = await SupabaseService.instance.testConnection();
      
      setState(() {
        _isConnected = connected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connected ? '✅ Supabase配置成功！' : '❌ 连接测试失败，请检查配置'),
            backgroundColor: connected ? Colors.green : Colors.red,
          ),
        );
      }

      if (connected && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 配置失败: $e'),
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
        title: const Text('Supabase配置'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _checkConnection,
            tooltip: _isConnected ? 'Supabase已连接' : 'Supabase未连接',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 连接状态卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: _isConnected ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected ? 'Supabase已连接' : 'Supabase未连接',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isConnected ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          Text(
                            _isConnected 
                                ? '数据将同步到云端数据库' 
                                : '当前使用本地存储，配置后可同步到云端',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isConnected ? Colors.green[600] : Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 配置说明
              Container(
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
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '如何获取Supabase配置？',
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
                      '1. 访问 https://supabase.com 并创建账户\n'
                      '2. 创建一个新项目\n'
                      '3. 在项目设置 → API 中找到：\n'
                      '   • Project URL\n'
                      '   • anon public key\n'
                      '4. 将这些信息填入下方表单',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // URL输入框
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Supabase项目URL',
                  hintText: 'https://your-project.supabase.co',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入Supabase项目URL';
                  }
                  if (!value.startsWith('https://') || !value.contains('supabase.co')) {
                    return '请输入有效的Supabase URL';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Key输入框
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Supabase Anon Key',
                  hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入Supabase Anon Key';
                  }
                  if (value.length < 100) {
                    return 'Anon Key长度不正确';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('正在保存配置...'),
                          ],
                        )
                      : const Text(
                          '保存配置并测试连接',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 测试连接按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _checkConnection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '测试当前连接',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 功能说明
              Container(
                padding: const EdgeInsets.all(16),
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
                        Icon(Icons.cloud_sync, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Supabase集成功能',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 学习进度云端同步\n'
                      '• 阅读偏好设置同步\n'
                      '• 多设备数据共享\n'
                      '• 学习统计分析\n'
                      '• 数据备份与恢复',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}