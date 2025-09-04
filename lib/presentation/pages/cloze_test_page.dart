import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/lesson.dart';
import '../../data/default_lessons.dart';

enum ClozeTestType {
  allLessons, // 所有课程
  selectedLessons, // 选择的课程
}

class ClozeTestSettings {
  final int questionCount;
  final ClozeTestType testType;
  final List<int> selectedLessons;

  const ClozeTestSettings({
    this.questionCount = 10,
    this.testType = ClozeTestType.allLessons,
    this.selectedLessons = const [],
  });

  ClozeTestSettings copyWith({
    int? questionCount,
    ClozeTestType? testType,
    List<int>? selectedLessons,
  }) {
    return ClozeTestSettings(
      questionCount: questionCount ?? this.questionCount,
      testType: testType ?? this.testType,
      selectedLessons: selectedLessons ?? this.selectedLessons,
    );
  }
}

class ClozeTestQuestion {
  final String sentence; // 带括号的句子
  final String originalSentence; // 原始句子
  final String correctWord; // 正确的单词
  final List<String> options; // 四个选项
  final int correctIndex; // 正确答案的索引
  final int lessonNumber; // 来源课程

  ClozeTestQuestion({
    required this.sentence,
    required this.originalSentence,
    required this.correctWord,
    required this.options,
    required this.correctIndex,
    required this.lessonNumber,
  });
}

class ClozeTestPage extends StatefulWidget {
  const ClozeTestPage({super.key});

  @override
  State<ClozeTestPage> createState() => _ClozeTestPageState();
}

class _ClozeTestPageState extends State<ClozeTestPage> {
  ClozeTestSettings _settings = const ClozeTestSettings();
  List<ClozeTestQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isTestCompleted = false;
  List<bool> _answerResults = [];
  FlutterTts? _flutterTts;
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

  Future<void> _initTts() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '完形填空',
          style: TextStyle(
            fontFamily: 'TimesNewRoman',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
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
            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
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
                  Icons.article,
                  size: 64,
                  color: Colors.green[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  '完形填空',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '在文章句子中选择正确的单词',
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
                          side: BorderSide(color: Colors.green[400]!),
                          foregroundColor: Colors.green[600],
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
                          backgroundColor: Colors.green[600],
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
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.quiz, size: 16, color: Colors.green),
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
              const Icon(Icons.book, size: 16, color: Colors.green),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
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
                // 题目说明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.article,
                              color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Lesson ${question.lessonNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请选择正确的单词填入空白处：',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 句子
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    question.sentence,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: Colors.black87,
                      fontFamily: 'TimesNewRoman',
                    ),
                    textAlign: TextAlign.center,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(ClozeTestQuestion question, int index) {
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
      cardColor = Colors.green[50]!;
      borderColor = Colors.green[400]!;
      textColor = Colors.green[700]!;
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
                  style: const TextStyle(
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
                  fontFamily: 'TimesNewRoman',
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
                  color:
                      accuracy >= 80 ? Colors.orange[600] : Colors.green[600],
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
                      Colors.green,
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
                          backgroundColor: Colors.green[600],
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
              title: const Text('完形填空设置'),
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
                            selectedColor: Colors.green[100],
                          );
                        }).toList(),
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
    // 收集所有可用的句子和词汇
    final availableSentences = <Map<String, dynamic>>[];

    // 根据设置选择课程
    final lessonsToUse = _settings.selectedLessons.isEmpty
        ? defaultLessons
        : defaultLessons
            .where(
                (lesson) => _settings.selectedLessons.contains(lesson.lesson))
            .toList();

    for (final lesson in lessonsToUse) {
      // 从课程内容中提取包含词汇的句子
      final sentences = lesson.content.split(RegExp(r'[.!?]+'));

      for (final sentence in sentences) {
        final trimmedSentence = sentence.trim();
        if (trimmedSentence.isEmpty) continue;

        // 检查句子中是否包含词汇表中的单词
        for (final vocab in lesson.vocabulary) {
          final wordPattern = RegExp(r'\b' + RegExp.escape(vocab.word) + r'\b',
              caseSensitive: false);
          if (wordPattern.hasMatch(trimmedSentence)) {
            availableSentences.add({
              'sentence': trimmedSentence,
              'word': vocab.word,
              'lesson': lesson.lesson,
              'allVocabulary':
                  lessonsToUse.expand((l) => l.vocabulary).toList(),
            });
          }
        }
      }
    }

    if (availableSentences.length < _settings.questionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('可用句子数量不足，当前只有 ${availableSentences.length} 个句子'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 随机选择句子并生成题目
    availableSentences.shuffle();
    final selectedSentences =
        availableSentences.take(_settings.questionCount).toList();

    _questions = selectedSentences.map((sentenceData) {
      return _generateClozeQuestion(
        sentenceData['sentence'],
        sentenceData['word'],
        sentenceData['lesson'],
        sentenceData['allVocabulary'],
      );
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

  ClozeTestQuestion _generateClozeQuestion(
    String sentence,
    String correctWord,
    int lessonNumber,
    List<Vocabulary> allVocabulary,
  ) {
    final random = Random();

    // 将句子中的正确单词替换为括号
    final wordPattern = RegExp(r'\b' + RegExp.escape(correctWord) + r'\b',
        caseSensitive: false);
    final sentenceWithBlanks = sentence.replaceAll(wordPattern, '(_______)');

    // 生成错误选项
    final wrongOptions = <String>[];
    final otherWords = allVocabulary
        .where((v) => v.word.toLowerCase() != correctWord.toLowerCase())
        .map((v) => v.word)
        .toList();

    while (wrongOptions.length < 3 && otherWords.isNotEmpty) {
      final randomWord = otherWords[random.nextInt(otherWords.length)];
      if (!wrongOptions.contains(randomWord)) {
        wrongOptions.add(randomWord);
      }
      otherWords.remove(randomWord);
    }

    // 补充选项（如果不够）
    while (wrongOptions.length < 3) {
      wrongOptions.add('option${wrongOptions.length + 1}');
    }

    // 随机排列选项
    final allOptions = [correctWord, ...wrongOptions];
    allOptions.shuffle();
    final correctIndex = allOptions.indexOf(correctWord);

    return ClozeTestQuestion(
      sentence: sentenceWithBlanks,
      originalSentence: sentence,
      correctWord: correctWord,
      options: allOptions,
      correctIndex: correctIndex,
      lessonNumber: lessonNumber,
    );
  }

  void _selectAnswer(int index) async {
    if (_isAnswered) return;

    final currentQuestion = _questions[_currentQuestionIndex];

    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;

      final isCorrectSel = index == currentQuestion.correctIndex;
      _answerResults.add(isCorrectSel);

      if (isCorrectSel) {
        _correctAnswers++;
      }
    });

    final isCorrect = index == currentQuestion.correctIndex;

    // 先朗读原始句子，再按正确/错误延迟
    try {
      if (_flutterTts != null) {
        _ttsCompleter = Completer<void>();
        await _flutterTts!.speak(currentQuestion.originalSentence);
        await _ttsCompleter!.future
            .timeout(const Duration(seconds: 15), onTimeout: () {});
        _ttsCompleter = null;
      }
    } catch (_) {
      // 忽略TTS错误，继续流程
    }

    final delayMs = isCorrect ? 1000 : 2000;
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!mounted) return;

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _isTestCompleted = true;
      });
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
    });
  }
}
