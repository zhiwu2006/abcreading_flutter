import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/lesson.dart';
import '../../data/default_lessons.dart';

enum TestType {
  wordToChinese, // 英语单词 -> 中文释义
  wordToEnglish, // 英语单词 -> 英语释义
}

class WordTestSettings {
  final int questionCount;
  final TestType testType;
  final List<int> selectedLessons; // 选中的课程ID列表

  const WordTestSettings({
    this.questionCount = 10,
    this.testType = TestType.wordToChinese,
    this.selectedLessons = const [], // 空列表表示选择所有课程
  });

  WordTestSettings copyWith({
    int? questionCount,
    TestType? testType,
    List<int>? selectedLessons,
  }) {
    return WordTestSettings(
      questionCount: questionCount ?? this.questionCount,
      testType: testType ?? this.testType,
      selectedLessons: selectedLessons ?? this.selectedLessons,
    );
  }
}

class WordTestQuestion {
  final String word;
  final String correctAnswer;
  final List<String> options;
  final int correctIndex;
  final String? exampleSentence; // 单词在文章中的例句
  final int lessonNumber; // 来源课程编号

  WordTestQuestion({
    required this.word,
    required this.correctAnswer,
    required this.options,
    required this.correctIndex,
    this.exampleSentence,
    required this.lessonNumber,
  });
}

class WordTestPage extends StatefulWidget {
  const WordTestPage({super.key});

  @override
  State<WordTestPage> createState() => _WordTestPageState();
}

class _WordTestPageState extends State<WordTestPage> {
  WordTestSettings _settings = const WordTestSettings();
  List<WordTestQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isTestCompleted = false;
  List<bool> _answerResults = [];

  // TTS和句子显示相关
  FlutterTts? _flutterTts;
  bool _showExampleSentence = false;
  bool _isPlayingTts = false;
  Completer<void>? _ttsCompleter;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts?.setLanguage("en-US");
    await _flutterTts?.setSpeechRate(0.5);
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
    await _flutterTts?.awaitSpeakCompletion(true);

    _flutterTts?.setCompletionHandler(() {
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
      if (mounted) {
        setState(() {
          _isPlayingTts = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '单词测试',
          style: TextStyle(
            fontFamily: 'TimesNewRoman',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isTestCompleted && _questions.isEmpty)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(),
              tooltip: '测试设置',
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
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isTestCompleted) {
      return _buildTestSummary();
    } else if (_questions.isEmpty) {
      return _buildStartScreen();
    } else {
      return _buildTestScreen();
    }
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.spellcheck,
                  size: 64,
                  color: Colors.blue[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  '单词测试',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '测试您的词汇掌握程度',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
                const SizedBox(height: 24),
                _buildCurrentSettings(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSettingsDialog(),
                        icon: const Icon(Icons.settings),
                        label: const Text('测试设置'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blue[400]!),
                          foregroundColor: Colors.blue[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startTest(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始测试'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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

  Widget _buildCurrentSettings() {
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
          const Text(
            '当前设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.quiz, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '题目数量: ${_settings.questionCount}题',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.translate, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '测试类型: ${_settings.testType == TestType.wordToChinese ? "英语→中文" : "英语→英语释义"}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.book, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '测试范围: ${_settings.selectedLessons.isEmpty ? "所有课程" : "${_settings.selectedLessons.length}个课程"}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestScreen() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 进度条
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '第 ${_currentQuestionIndex + 1} 题',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_currentQuestionIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 题目卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 题目
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _settings.testType == TestType.wordToChinese
                            ? '请选择下列单词的正确中文释义：'
                            : '请选择下列单词的正确英语释义：',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.word,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'TimesNewRoman',
                        ),
                      ),
                    ],
                  ),
                ),

                // 选项
                const SizedBox(height: 24),
                _buildOptionCard(question, 0),
                const SizedBox(height: 12),
                _buildOptionCard(question, 1),
                const SizedBox(height: 12),
                _buildOptionCard(question, 2),
                const SizedBox(height: 12),
                _buildOptionCard(question, 3),

                // 例句显示区域（仅在英语→中文模式且已答题时显示）
                if (_showExampleSentence &&
                    _settings.testType == TestType.wordToChinese &&
                    question.exampleSentence != null)
                  _buildExampleSentenceCard(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(WordTestQuestion question, int index) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == question.correctIndex;
    final isWrong = _isAnswered && isSelected && !isCorrect;
    final shouldShowCorrect = _isAnswered && isCorrect;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;

    if (_isAnswered) {
      if (isCorrect) {
        cardColor = Colors.green[50]!;
        borderColor = Colors.green[400]!;
        textColor = Colors.green[700]!;
      } else if (isWrong) {
        cardColor = Colors.red[50]!;
        borderColor = Colors.red[400]!;
        textColor = Colors.red[700]!;
      }
    } else if (isSelected) {
      cardColor = Colors.blue[50]!;
      borderColor = Colors.blue[400]!;
      textColor = Colors.blue[700]!;
    }

    return InkWell(
      onTap: _isAnswered ? null : () => _selectAnswer(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_isAnswered && isCorrect)
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 24,
              ),
            if (_isAnswered && isWrong)
              Icon(
                Icons.cancel,
                color: Colors.red[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleSentenceCard(WordTestQuestion question) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 1,
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
                Icons.article,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lesson ${question.lessonNumber} - 例句',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isPlayingTts)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                  ),
                )
              else
                Icon(
                  Icons.volume_up,
                  color: Colors.green[600],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.exampleSentence!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
              fontFamily: 'TimesNewRoman',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正在朗读例句...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSummary() {
    final accuracy = (_correctAnswers / _questions.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  accuracy >= 80 ? Icons.emoji_events : Icons.assessment,
                  size: 64,
                  color: accuracy >= 80 ? Colors.orange[600] : Colors.blue[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  '测试完成！',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // 成绩统计
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      '正确率',
                      '$accuracy%',
                      Icons.trending_up,
                      accuracy >= 80 ? Colors.green : Colors.orange,
                    ),
                    _buildStatCard(
                      '正确题数',
                      '$_correctAnswers/${_questions.length}',
                      Icons.check_circle,
                      Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _resetTest(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新测试'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text('返回首页'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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

  Widget _buildStatCard(
      String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color[600]),
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
              color: color[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('测试设置'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '题目数量',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [5, 10, 15, 20, 50, 100].map((count) {
                          final isSelected = _settings.questionCount == count;
                          return FilterChip(
                            label: Text('$count题'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  _settings =
                                      _settings.copyWith(questionCount: count);
                                });
                              }
                            },
                            selectedColor: Colors.blue[100],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '测试类型',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<TestType>(
                            title: const Text('英语单词 → 中文释义'),
                            value: TestType.wordToChinese,
                            groupValue: _settings.testType,
                            onChanged: (value) {
                              setDialogState(() {
                                _settings = _settings.copyWith(testType: value);
                              });
                            },
                          ),
                          RadioListTile<TestType>(
                            title: const Text('英语单词 → 英语释义'),
                            value: TestType.wordToEnglish,
                            groupValue: _settings.testType,
                            onChanged: (value) {
                              setDialogState(() {
                                _settings = _settings.copyWith(testType: value);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '测试范围',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // 全选/取消全选按钮
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border(
                                    bottom:
                                        BorderSide(color: Colors.grey[300]!)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _settings.selectedLessons.isEmpty
                                          ? '已选择所有课程'
                                          : '已选择 ${_settings.selectedLessons.length} 个课程',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        if (_settings.selectedLessons.length ==
                                            defaultLessons.length) {
                                          // 如果全选了，则取消全选
                                          _settings = _settings
                                              .copyWith(selectedLessons: []);
                                        } else {
                                          // 否则全选
                                          _settings = _settings.copyWith(
                                            selectedLessons: defaultLessons
                                                .map((l) => l.lesson)
                                                .toList(),
                                          );
                                        }
                                      });
                                    },
                                    child: Text(
                                      _settings.selectedLessons.length ==
                                              defaultLessons.length
                                          ? '取消全选'
                                          : '全选',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 课程列表
                            Expanded(
                              child: ListView.builder(
                                itemCount: defaultLessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = defaultLessons[index];
                                  final isSelected =
                                      _settings.selectedLessons.isEmpty ||
                                          _settings.selectedLessons
                                              .contains(lesson.lesson);

                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(
                                      'Lesson ${lesson.lesson}: ${lesson.title}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '${lesson.vocabulary.length} 个单词',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setDialogState(() {
                                        List<int> newSelected = List.from(
                                            _settings.selectedLessons);

                                        if (value == true) {
                                          if (!newSelected
                                              .contains(lesson.lesson)) {
                                            newSelected.add(lesson.lesson);
                                          }
                                        } else {
                                          newSelected.remove(lesson.lesson);
                                        }

                                        _settings = _settings.copyWith(
                                            selectedLessons: newSelected);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startTest() {
    final allVocabulary = <Vocabulary>[];

    // 根据选择的课程收集词汇
    if (_settings.selectedLessons.isEmpty) {
      // 如果没有选择特定课程，使用所有课程
      for (final lesson in defaultLessons) {
        allVocabulary.addAll(lesson.vocabulary);
      }
    } else {
      // 只收集选中课程的词汇
      for (final lesson in defaultLessons) {
        if (_settings.selectedLessons.contains(lesson.lesson)) {
          allVocabulary.addAll(lesson.vocabulary);
        }
      }
    }

    print('收集到的词汇数量: ${allVocabulary.length}');
    print('测试类型: ${_settings.testType}');
    print(
        '选择的课程: ${_settings.selectedLessons.isEmpty ? "所有课程" : _settings.selectedLessons}');

    if (allVocabulary.length < _settings.questionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('词汇数量不足，当前只有 ${allVocabulary.length} 个词汇'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 随机选择词汇并生成题目
    allVocabulary.shuffle();
    final selectedVocabulary =
        allVocabulary.take(_settings.questionCount).toList();

    _questions = selectedVocabulary.map((vocab) {
      final question = _generateQuestion(vocab, allVocabulary);
      print('生成题目: ${question.word} -> 正确答案: ${question.correctAnswer}');
      print('选项: ${question.options}');
      return question;
    }).toList();

    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _isTestCompleted = false;
      _answerResults.clear();
    });
  }

  WordTestQuestion _generateQuestion(
      Vocabulary targetVocab, List<Vocabulary> allVocabulary) {
    final random = Random();

    String questionWord;
    String correctAnswer;

    if (_settings.testType == TestType.wordToChinese) {
      // 英语单词 -> 中文释义
      questionWord = targetVocab.word;
      // 如果有分号，取分号后面的中文部分；否则取整个meaning
      final meaningParts = targetVocab.meaning.split(';');
      correctAnswer = meaningParts.length > 1
          ? meaningParts[1].trim()
          : meaningParts[0].trim();
    } else {
      // 英语单词 -> 英语释义
      questionWord = targetVocab.word;
      // 如果有分号，取分号前面的英语释义部分；否则取整个meaning
      final meaningParts = targetVocab.meaning.split(';');
      correctAnswer = meaningParts[0].trim();
    }

    // 生成错误选项
    final wrongOptions = <String>[];
    final otherVocabulary =
        allVocabulary.where((v) => v.word != targetVocab.word).toList();

    while (wrongOptions.length < 3 && otherVocabulary.isNotEmpty) {
      final randomVocab =
          otherVocabulary[random.nextInt(otherVocabulary.length)];
      String option;
      if (_settings.testType == TestType.wordToChinese) {
        // 英语单词 -> 中文释义，选项应该是中文
        final meaningParts = randomVocab.meaning.split(';');
        option = meaningParts.length > 1
            ? meaningParts[1].trim()
            : meaningParts[0].trim();
      } else {
        // 英语单词 -> 英语释义，选项应该是英语释义
        final meaningParts = randomVocab.meaning.split(';');
        option = meaningParts[0].trim();
      }

      if (!wrongOptions.contains(option) && option != correctAnswer) {
        wrongOptions.add(option);
      }
      otherVocabulary.remove(randomVocab);
    }

    // 补充选项（如果不够）
    while (wrongOptions.length < 3) {
      wrongOptions.add('选项 ${wrongOptions.length + 1}');
    }

    // 随机排列选项
    final allOptions = [correctAnswer, ...wrongOptions];
    allOptions.shuffle();
    final correctIndex = allOptions.indexOf(correctAnswer);

    return WordTestQuestion(
      word: questionWord,
      correctAnswer: correctAnswer,
      options: allOptions,
      correctIndex: correctIndex,
      exampleSentence: _findExampleSentence(targetVocab.word, allVocabulary),
      lessonNumber: _findLessonNumber(targetVocab.word),
    );
  }

  String? _findExampleSentence(String word, List<Vocabulary> allVocabulary) {
    // 在课程内容中查找包含该单词的句子
    for (final lesson in defaultLessons) {
      final sentences = lesson.content.split(RegExp(r'[.!?]+'));
      for (final sentence in sentences) {
        final trimmedSentence = sentence.trim();
        if (trimmedSentence.isEmpty) continue;

        // 检查句子是否包含目标单词（不区分大小写）
        final wordPattern =
            RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
        if (wordPattern.hasMatch(trimmedSentence)) {
          return trimmedSentence;
        }
      }
    }
    return null;
  }

  int _findLessonNumber(String word) {
    // 查找单词所属的课程编号
    for (final lesson in defaultLessons) {
      for (final vocab in lesson.vocabulary) {
        if (vocab.word.toLowerCase() == word.toLowerCase()) {
          return lesson.lesson;
        }
      }
    }
    return 1; // 默认返回第1课
  }

  String _generateEnglishDefinition(String word) {
    // 简单的英语定义生成器
    final definitions = {
      'hello': 'a greeting used when meeting someone',
      'world': 'the earth and all the people and things on it',
      'book': 'a set of printed pages that are held together',
      'water': 'a clear liquid that has no color or taste',
      'house': 'a building where people live',
      'car': 'a vehicle with four wheels that uses an engine',
      'tree': 'a large plant that has a wooden trunk',
      'sun': 'the star that provides light and heat to Earth',
      'moon': 'the natural satellite of Earth',
      'computer': 'an electronic device for processing data',
      'phone': 'a device used for talking to people far away',
      'school': 'an institution for education',
      'friend': 'a person you know well and like',
      'family': 'a group of related people',
    };

    return definitions[word.toLowerCase()] ?? 'a word in English';
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;

      final isCorrect = index == _questions[_currentQuestionIndex].correctIndex;
      _answerResults.add(isCorrect);

      if (isCorrect) {
        _correctAnswers++;
      }
    });

    // 在英语→中文模式下显示例句并朗读
    if (_settings.testType == TestType.wordToChinese &&
        _questions[_currentQuestionIndex].exampleSentence != null) {
      _showExampleSentenceAndSpeak();
    } else {
      // 其他模式直接进入下一题
      _proceedToNextQuestion();
    }
  }

  void _showExampleSentenceAndSpeak() async {
    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == question.correctIndex;

    setState(() {
      _showExampleSentence = true;
    });

    // 等待一小段时间让动画显示
    await Future.delayed(const Duration(milliseconds: 500));

    // 开始朗读例句
    if (question.exampleSentence != null && _flutterTts != null) {
      setState(() {
        _isPlayingTts = true;
      });

      _ttsCompleter = Completer<void>();
      await _flutterTts!.speak(question.exampleSentence!);
      await _ttsCompleter!.future;
      _ttsCompleter = null;

      // 朗读完成后，根据答案正确性决定额外等待时间
      final additionalDelay = isCorrect ? 1000 : 2000; // 正确1秒，错误2秒
      await Future.delayed(Duration(milliseconds: additionalDelay));
    } else {
      // 如果没有例句，使用默认延时
      final delay = isCorrect ? 1000 : 2000;
      await Future.delayed(Duration(milliseconds: delay));
    }

    // 直接进入下一题，不再额外延时
    _goToNextQuestion();
  }

  void _proceedToNextQuestion() {
    final delay =
        _selectedAnswer == _questions[_currentQuestionIndex].correctIndex
            ? 1000
            : 2000;

    Future.delayed(Duration(milliseconds: delay), () {
      _goToNextQuestion();
    });
  }

  void _goToNextQuestion() {
    if (mounted) {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswered = false;
          _selectedAnswer = null;
          _showExampleSentence = false;
          _isPlayingTts = false;
        });
      } else {
        setState(() {
          _isTestCompleted = true;
          _showExampleSentence = false;
          _isPlayingTts = false;
        });
      }
    }
  }

  void _resetTest() {
    setState(() {
      _questions.clear();
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _isTestCompleted = false;
      _answerResults.clear();
      _showExampleSentence = false;
      _isPlayingTts = false;
    });
  }
}
