import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/lesson.dart';
import '../../services/lesson_manager_service.dart';
import 'lesson_detail_editor_page.dart';


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
  
  // 多选功能相关状态
  bool _isMultiSelectMode = false;
  Set<int> _selectedLessonIds = <int>{};

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
      final confirmed = await _showPreviewDialog(newLessons);
      
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

  Future<bool?> _showPreviewDialog(List<Lesson> lessons) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('课程预览 (${lessons.length}个)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${lesson.lesson}')),
                title: Text(lesson.title),
                subtitle: Text('词汇: ${lesson.vocabulary.length} | 句子: ${lesson.sentences.length} | 题目: ${lesson.questions.length}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importLessons(List<Lesson> newLessons) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用 LessonManagerService 添加课程（会同步到本地缓存）
      final success = await LessonManagerService.instance.addLessons(newLessons);
      
      if (success) {
        // 重新加载课程列表
        await _loadLocalLessons();
        
        // 计算实际添加的课程数量
        final existingNumbers = _localLessons.map((l) => l.lesson).toSet();
        final addedLessons = newLessons.where((lesson) => existingNumbers.contains(lesson.lesson)).toList();
        final duplicates = newLessons.where((lesson) => !existingNumbers.contains(lesson.lesson)).map((l) => l.lesson).toList();
        
        // 显示导入结果
        String message = '✅ 成功导入 ${addedLessons.length} 个课程到本地缓存';
        if (duplicates.isNotEmpty) {
          message += '\n⚠️ 跳过重复课程: ${duplicates.join(', ')}';
        }
        message += '\n💡 提示：使用同步按钮可将更改上传到数据库';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('所有课程都已存在或导入失败');
      }

      // 清空输入框
      _jsonController.clear();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败: $e'),
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

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除第${lesson.lesson}课"${lesson.title}"吗？\n\n此操作将从本地缓存中删除，使用同步按钮可同步到数据库。'),
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
        _isLoading = true;
      });

      try {
        // 使用 LessonManagerService 删除课程（会从本地缓存删除）
        final success = await LessonManagerService.instance.deleteLesson(lesson.lesson);
        
        if (success) {
          // 重新加载课程列表
          await _loadLocalLessons();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 已删除第${lesson.lesson}课\n💡 提示：使用同步按钮可将更改上传到数据库'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('删除操作失败');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 删除失败: $e'),
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
  }

  // 多选功能方法
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedLessonIds.clear();
      }
    });
  }

  void _toggleLessonSelection(int lessonId) {
    setState(() {
      if (_selectedLessonIds.contains(lessonId)) {
        _selectedLessonIds.remove(lessonId);
      } else {
        _selectedLessonIds.add(lessonId);
      }
    });
  }

  void _selectAllLessons() {
    setState(() {
      _selectedLessonIds = _localLessons.map((lesson) => lesson.lesson).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedLessonIds.clear();
    });
  }

  Future<void> _deleteSelectedLessons() async {
    if (_selectedLessonIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除课程'),
        content: Text('确定要删除选中的 ${_selectedLessonIds.length} 个课程吗？\n\n此操作将从本地缓存中删除，使用同步按钮可同步到数据库。'),
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
        _isLoading = true;
      });

      try {
        // 使用 LessonManagerService 批量删除课程（会从本地缓存删除）
        final lessonNumbersToDelete = _selectedLessonIds.toList();
        final success = await LessonManagerService.instance.deleteLessons(lessonNumbersToDelete);
        
        if (success) {
          // 重新加载课程列表
          await _loadLocalLessons();
          
          setState(() {
            _selectedLessonIds.clear();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 已删除 ${lessonNumbersToDelete.length} 个课程\n💡 提示：使用同步按钮可将更改上传到数据库'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('批量删除操作失败');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 批量删除失败: $e'),
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
  }

  Future<void> _exportSelectedLessons() async {
    if (_selectedLessonIds.isEmpty) return;

    final selectedLessons = _localLessons
        .where((lesson) => _selectedLessonIds.contains(lesson.lesson))
        .toList();

    final jsonString = json.encode(selectedLessons.map((lesson) => lesson.toJson()).toList());

    await Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已复制 ${selectedLessons.length} 个课程到剪贴板'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 数据库同步功能
  Future<void> _syncToDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 上传本地课程到远程数据库
      final success = await LessonManagerService.instance.uploadLocalToRemote();
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 成功同步 ${_localLessons.length} 个课程到数据库'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('同步失败，请检查网络连接和数据库配置');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 同步到数据库失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从远程数据库同步到本地
      final success = await LessonManagerService.instance.syncRemoteToLocal();
      
      if (success) {
        // 重新加载本地课程列表
        await _loadLocalLessons();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 成功从数据库同步 ${_localLessons.length} 个课程'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('同步失败，请检查网络连接和数据库配置');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 从数据库同步失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSyncDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据库同步'),
        content: const Text('请选择同步方向：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'from_db'),
            child: const Text('从数据库同步到本地'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'to_db'),
            child: const Text('上传本地到数据库'),
          ),
        ],
      ),
    );

    if (action == 'to_db') {
      await _syncToDatabase();
    } else if (action == 'from_db') {
      await _syncFromDatabase();
    }
  }

  Future<void> _navigateToLessonDetail(Lesson lesson) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailEditorPage(lesson: lesson),
      ),
    );

    // 如果从详情页面返回，重新加载课程列表
    if (result == true || mounted) {
      await _loadLocalLessons();
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
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllLessons,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: '清除选择',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _selectedLessonIds.isNotEmpty ? _exportSelectedLessons : null,
              tooltip: '导出选中',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedLessonIds.isNotEmpty ? _deleteSelectedLessons : null,
              tooltip: '删除选中',
            ),
          ],
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: _toggleMultiSelectMode,
            tooltip: _isMultiSelectMode ? '退出多选' : '多选模式',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: _isLoading ? null : _showSyncDialog,
            tooltip: '数据库同步',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('课程导入格式说明'),
                  content: const Text('支持JSON格式的课程数据\n\n格式要求：\n• 单个课程对象\n• 课程数组\n\n必需字段：lesson, title, content, vocabulary, sentences, questions'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            },
            tooltip: '导入格式说明',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocalLessons,
            tooltip: '刷新课程列表',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 课程列表
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '本地课程列表 (${_localLessons.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isMultiSelectMode)
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: _isLoading ? null : _showSyncDialog,
                                      icon: const Icon(Icons.cloud_sync, size: 16),
                                      label: const Text('同步数据库'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (_isMultiSelectMode && _selectedLessonIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '已选择 ${_selectedLessonIds.length} 个',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 400,
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _localLessons.isEmpty
                          ? const Center(
                              child: Text(
                                '暂无课程数据\n请使用下方导入功能添加课程',
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
                                final isSelected = _selectedLessonIds.contains(lesson.lesson);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: _isMultiSelectMode && isSelected 
                                      ? Colors.blue[50] 
                                      : null,
                                  child: ListTile(
                                    leading: _isMultiSelectMode
                                        ? Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              _toggleLessonSelection(lesson.lesson);
                                            },
                                          )
                                        : CircleAvatar(
                                            child: Text('${lesson.lesson}'),
                                          ),
                                    title: Text(lesson.title),
                                    subtitle: Text(
                                      '词汇: ${lesson.vocabulary.length} | 句子: ${lesson.sentences.length} | 题目: ${lesson.questions.length}',
                                    ),
                                    trailing: _isMultiSelectMode
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _deleteLesson(lesson),
                                            tooltip: '删除课程',
                                          ),
                                    onTap: _isMultiSelectMode
                                        ? () => _toggleLessonSelection(lesson.lesson)
                                        : () => _navigateToLessonDetail(lesson),
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
            
            // 导入区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '导入新课程',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pasteFromClipboard,
                            icon: const Icon(Icons.content_paste),
                            label: const Text('粘贴内容'),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isMultiSelectMode && _selectedLessonIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportSelectedLessons,
                      icon: const Icon(Icons.file_download),
                      label: Text('导出 (${_selectedLessonIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteSelectedLessons,
                      icon: const Icon(Icons.delete),
                      label: Text('删除 (${_selectedLessonIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}