import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../services/lesson_manager_service.dart';

class LessonDetailEditorPage extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailEditorPage({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonDetailEditorPage> createState() => _LessonDetailEditorPageState();
}

class _LessonDetailEditorPageState extends State<LessonDetailEditorPage> {
  late TextEditingController _lessonNumberController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  final List<Map<String, TextEditingController>> _vocabularyControllers = [];
  final List<Map<String, TextEditingController>> _sentenceControllers = [];
  final List<Map<String, dynamic>> _questionControllers = [];
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _lessonNumberController = TextEditingController(text: widget.lesson.lesson.toString());
    _titleController = TextEditingController(text: widget.lesson.title);
    _contentController = TextEditingController(text: widget.lesson.content);
    
    // 监听变化
    _lessonNumberController.addListener(_onDataChanged);
    _titleController.addListener(_onDataChanged);
    _contentController.addListener(_onDataChanged);

    // 初始化词汇控制器
    for (var vocab in widget.lesson.vocabulary) {
      final controllers = {
        'word': TextEditingController(text: vocab.word),
        'meaning': TextEditingController(text: vocab.meaning),
      };
      controllers['word']!.addListener(_onDataChanged);
      controllers['meaning']!.addListener(_onDataChanged);
      _vocabularyControllers.add(controllers);
    }

    // 初始化句子控制器
    for (var sentence in widget.lesson.sentences) {
      final controllers = {
        'text': TextEditingController(text: sentence.text),
        'note': TextEditingController(text: sentence.note),
      };
      controllers['text']!.addListener(_onDataChanged);
      controllers['note']!.addListener(_onDataChanged);
      _sentenceControllers.add(controllers);
    }

    // 初始化问题控制器
    for (var question in widget.lesson.questions) {
      final controllers = {
        'question': TextEditingController(text: question.question),
        'optionA': TextEditingController(text: question.options.a),
        'optionB': TextEditingController(text: question.options.b),
        'optionC': TextEditingController(text: question.options.c),
        'optionD': TextEditingController(text: question.options.d),
        'answer': question.answer,
      };
      (controllers['question'] as TextEditingController).addListener(_onDataChanged);
      (controllers['optionA'] as TextEditingController).addListener(_onDataChanged);
      (controllers['optionB'] as TextEditingController).addListener(_onDataChanged);
      (controllers['optionC'] as TextEditingController).addListener(_onDataChanged);
      (controllers['optionD'] as TextEditingController).addListener(_onDataChanged);
      _questionControllers.add(controllers);
    }
  }

  void _onDataChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _lessonNumberController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    
    // 释放词汇控制器
    for (var controllers in _vocabularyControllers) {
      controllers['word']?.dispose();
      controllers['meaning']?.dispose();
    }
    
    // 释放句子控制器
    for (var controllers in _sentenceControllers) {
      controllers['text']?.dispose();
      controllers['note']?.dispose();
    }
    
    // 释放问题控制器
    for (var controllers in _questionControllers) {
      controllers['question']?.dispose();
      controllers['optionA']?.dispose();
      controllers['optionB']?.dispose();
      controllers['optionC']?.dispose();
      controllers['optionD']?.dispose();
    }
    
    super.dispose();
  }

  Future<void> _saveLessonChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建更新后的课程对象
      final updatedLesson = Lesson(
        lesson: int.parse(_lessonNumberController.text),
        title: _titleController.text,
        content: _contentController.text,
        vocabulary: _vocabularyControllers
            .map((controllers) => Vocabulary(
                  word: controllers['word']!.text,
                  meaning: controllers['meaning']!.text,
                ))
            .toList(),
        sentences: _sentenceControllers
            .map((controllers) => Sentence(
                  text: controllers['text']!.text,
                  note: controllers['note']!.text,
                ))
            .toList(),
        questions: _questionControllers
            .map((controllers) => Question(
                  question: controllers['question']!.text,
                  options: QuestionOptions(
                    a: controllers['optionA']!.text,
                    b: controllers['optionB']!.text,
                    c: controllers['optionC']!.text,
                    d: controllers['optionD']!.text,
                  ),
                  answer: controllers['answer'] as String,
                ))
            .toList(),
      );

      // 先删除原课程，再添加更新后的课程
      await LessonManagerService.instance.deleteLesson(widget.lesson.lesson);
      await LessonManagerService.instance.addLessons([updatedLesson]);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 课程已保存到本地缓存\n💡 提示：使用同步按钮可将更改上传到数据库'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 保存失败: $e'),
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('离开'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _saveLessonChanges();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('保存并离开'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            '编辑第${widget.lesson.lesson}课',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _isLoading ? null : _saveLessonChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  tooltip: '保存更改',
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 基本信息
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              
              // 词汇列表
              _buildVocabularyCard(),
              const SizedBox(height: 16),
              
              // 句子列表
              _buildSentencesCard(),
              const SizedBox(height: 16),
              
              // 问题列表
              _buildQuestionsCard(),
              const SizedBox(height: 80), // 为浮动按钮留空间
            ],
          ),
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveLessonChanges,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? '保存中...' : '保存更改'),
                backgroundColor: Colors.green,
              )
            : null,
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _lessonNumberController,
              decoration: const InputDecoration(
                labelText: '课程编号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '课程标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '课程内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '词汇 (${_vocabularyControllers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final controllers = {
                        'word': TextEditingController(),
                        'meaning': TextEditingController(),
                      };
                      controllers['word']!.addListener(_onDataChanged);
                      controllers['meaning']!.addListener(_onDataChanged);
                      _vocabularyControllers.add(controllers);
                      _onDataChanged();
                    });
                  },
                  icon: const Icon(Icons.add),
                  tooltip: '添加词汇',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._vocabularyControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controllers['word'],
                        decoration: const InputDecoration(
                          labelText: '单词',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controllers['meaning'],
                        decoration: const InputDecoration(
                          labelText: '含义',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          controllers['word']?.dispose();
                          controllers['meaning']?.dispose();
                          _vocabularyControllers.removeAt(index);
                          _onDataChanged();
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '删除',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSentencesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '句子 (${_sentenceControllers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final controllers = {
                        'text': TextEditingController(),
                        'note': TextEditingController(),
                      };
                      controllers['text']!.addListener(_onDataChanged);
                      controllers['note']!.addListener(_onDataChanged);
                      _sentenceControllers.add(controllers);
                      _onDataChanged();
                    });
                  },
                  icon: const Icon(Icons.add),
                  tooltip: '添加句子',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._sentenceControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: controllers['text'],
                      decoration: const InputDecoration(
                        labelText: '句子内容',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers['note'],
                            decoration: const InputDecoration(
                              labelText: '注释',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              controllers['text']?.dispose();
                              controllers['note']?.dispose();
                              _sentenceControllers.removeAt(index);
                              _onDataChanged();
                            });
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '问题 (${_questionControllers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final controllers = {
                        'question': TextEditingController(),
                        'optionA': TextEditingController(),
                        'optionB': TextEditingController(),
                        'optionC': TextEditingController(),
                        'optionD': TextEditingController(),
                        'answer': 'A',
                      };
                      (controllers['question'] as TextEditingController).addListener(_onDataChanged);
                      (controllers['optionA'] as TextEditingController).addListener(_onDataChanged);
                      (controllers['optionB'] as TextEditingController).addListener(_onDataChanged);
                      (controllers['optionC'] as TextEditingController).addListener(_onDataChanged);
                      (controllers['optionD'] as TextEditingController).addListener(_onDataChanged);
                      _questionControllers.add(controllers);
                      _onDataChanged();
                    });
                  },
                  icon: const Icon(Icons.add),
                  tooltip: '添加问题',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._questionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers['question'] as TextEditingController,
                            decoration: const InputDecoration(
                              labelText: '问题',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              controllers['question']?.dispose();
                              controllers['optionA']?.dispose();
                              controllers['optionB']?.dispose();
                              controllers['optionC']?.dispose();
                              controllers['optionD']?.dispose();
                              _questionControllers.removeAt(index);
                              _onDataChanged();
                            });
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 选项A和B
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers['optionA'] as TextEditingController,
                            decoration: const InputDecoration(
                              labelText: '选项 A',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controllers['optionB'] as TextEditingController,
                            decoration: const InputDecoration(
                              labelText: '选项 B',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 选项C和D
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers['optionC'] as TextEditingController,
                            decoration: const InputDecoration(
                              labelText: '选项 C',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controllers['optionD'],
                            decoration: const InputDecoration(
                              labelText: '选项 D',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 正确答案
                    DropdownButtonFormField<String>(
                      initialValue: controllers['answer'] as String,
                      decoration: const InputDecoration(
                        labelText: '正确答案',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['A', 'B', 'C', 'D']
                          .map((answer) => DropdownMenuItem(
                                value: answer,
                                child: Text('选项 $answer'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            controllers['answer'] = value;
                            _onDataChanged();
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

