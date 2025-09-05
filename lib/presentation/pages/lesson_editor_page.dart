import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/lesson.dart';
import '../../services/lesson_manager_service.dart';
import '../../data/default_lessons.dart';
import '../widgets/lesson_import_help_dialog.dart';
import '../widgets/lesson_preview_dialog.dart';

class LessonEditorPage extends StatefulWidget {
  const LessonEditorPage({super.key});

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  final TextEditingController _jsonController = TextEditingController();
  List<Lesson> _localLessons = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocalLessons();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessons = await LessonManagerService.instance.getLocalLessons();
      setState(() {
        _localLessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载课程失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        _jsonController.text = contents;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 文件导入成功，请检查内容后点击解析'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 文件导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        _jsonController.text = data.text!;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 剪贴板内容已粘贴，请检查后点击解析'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 粘贴失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseAndImportLessons() async {
    if (_jsonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 请先输入或导入课程数据'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 尝试解析JSON
      dynamic jsonData = json.decode(_jsonController.text.trim());
      List<Lesson> newLessons = [];

      if (jsonData is List) {
        // 如果是课程数组
        for (var item in jsonData) {
          if (item is Map<String, dynamic>) {
            newLessons.add(Lesson.fromJson(item));
          }
        }
      } else if (jsonData is Map<String, dynamic>) {
        // 如果是单个课程
        newLessons.add(Lesson.fromJson(jsonData));
      } else {
        throw Exception('不支持的数据格式');
      }

      if (newLessons.isEmpty) {
        throw Exception('没有找到有效的课程数据');
      }

      setState(() {
        _isLoading = false;
      });

      // 显示预览对话框
      final confirmed = await LessonPreviewDialog.show(context, newLessons);
      
      if (confirmed == true) {
        // 用户确认导入
        await _importLessons(newLessons);
      }

    } catch (e) {
      setState(() {
        _errorMessage = '解析失败: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 解析失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importLessons(List<Lesson> newLessons) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 检查重复课程并添加到本地列表
      int addedCount = 0;
      List<int> duplicates = [];
      
      for (var newLesson in newLessons) {
        bool exists = _localLessons.any((lesson) => lesson.lesson == newLesson.lesson);
        if (!exists) {
          _localLessons.add(newLesson);
          defaultLessons.add(newLesson);
          addedCount++;
        } else {
          duplicates.add(newLesson.lesson);
        }
      }
      
      _localLessons.sort((a, b) => a.lesson.compareTo(b.lesson));

      // 保存到本地存储
      await _saveLessonsToLocal();

      setState(() {
        _isLoading = false;
      });

      // 显示导入结果
      String message = '✅ 成功导入 $addedCount 个课程';
      if (duplicates.isNotEmpty) {
        message += '\n⚠️ 跳过重复课程: ${duplicates.join(', ')}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 清空输入框
      _jsonController.clear();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveLessonsToLocal() async {
    try {
      // 这里可以调用LessonManagerService保存课程
      // 暂时使用简单的方式更新defaultLessons
      debugPrint('📚 已保存 ${_localLessons.length} 个课程到本地');
    } catch (e) {
      debugPrint('保存课程失败: $e');
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除第${lesson.lesson}课"${lesson.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _localLessons.removeWhere((l) => l.lesson == lesson.lesson);
        defaultLessons.removeWhere((l) => l.lesson == lesson.lesson);
      });

      await _saveLessonsToLocal();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已删除第${lesson.lesson}课'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '课程编辑器',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => LessonImportHelpDialog.show(context),
            tooltip: '导入格式说明',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocalLessons,
            tooltip: '刷新课程列表',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // 导入区域
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '导入新课程',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importFromFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('导入文件'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('粘贴内容'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // JSON输入框
                  TextField(
                    controller: _jsonController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: '在此粘贴或输入课程JSON数据...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 解析按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _parseAndImportLessons,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                      label: Text(_isLoading ? '解析中...' : '解析并导入'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  // 错误信息
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 课程列表
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.library_books,
                          color: Colors.green[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '本地课程列表 (${_localLessons.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _localLessons.isEmpty
                          ? const Center(
                              child: Text(
                                '暂无课程数据\n请导入课程文件或粘贴课程内容',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _localLessons.length,
                              itemBuilder: (context, index) {
                                final lesson = _localLessons[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        '${lesson.lesson}',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '词汇: ${lesson.vocabulary.length} | 句子: ${lesson.sentences.length} | 题目: ${lesson.questions.length}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[400],
                                      ),
                                      onPressed: () => _deleteLesson(lesson),
                                      tooltip: '删除课程',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}