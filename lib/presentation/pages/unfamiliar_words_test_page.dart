import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:math';
import '../../data/default_lessons.dart';
import '../../models/lesson.dart';

class UnfamiliarWordsTestPage extends StatefulWidget {
  final List<String> unfamiliarWords;

  const UnfamiliarWordsTestPage({
    super.key,
    required this.unfamiliarWords,
  });

  @override
  State<UnfamiliarWordsTestPage> createState() =>
      _UnfamiliarWordsTestPageState();
}

class _UnfamiliarWordsTestPageState extends State<UnfamiliarWordsTestPage> {
  FlutterTts? _flutterTts;
  Completer<void>? _ttsCompleter;
  bool _isPlayingTts = false;

  List<UnfamiliarTestQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _hasAnswered = false;
  int? _selectedAnswerIndex;
  bool _isTestCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _generateQuestions();
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
    await _flutterTts!.awaitSpeakCompletion(true);

    _flutterTts!.setCompletionHandler(() {
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
      setState(() {
        _isPlayingTts = false;
      });
    });
  }

  void _generateQuestions() {
    final random = Random();
    final allVocabulary = <Vocabulary>[];

    // 收集所有词汇
    for (final lesson in defaultLessons) {
      allVocabulary.addAll(lesson.vocabulary);
    }

    // 为每个不熟悉单词生成问题
    for (final word in widget.unfamiliarWords) {
      final targetVocab = allVocabulary.firstWhere(
        (v) => v.word == word,
        orElse: () => Vocabulary(word: word, meaning: ''),
      );

      if (targetVocab.meaning.isNotEmpty) {
        final parts = _splitMeaning(targetVocab.meaning);
        final correctAnswer = parts.$2; // 中文释义

        // 生成干扰项
        final distractors = <String>[];
        final otherVocabs = allVocabulary.where((v) => v.word != word).toList();

        while (distractors.length < 3 && otherVocabs.isNotEmpty) {
          final randomVocab = otherVocabs[random.nextInt(otherVocabs.length)];
          final distractorParts = _splitMeaning(randomVocab.meaning);
          final distractor = distractorParts.$2;

          if (distractor != correctAnswer &&
              !distractors.contains(distractor)) {
            distractors.add(distractor);
          }
          otherVocabs.remove(randomVocab);
        }

        // 补齐选项
        while (distractors.length < 3) {
          distractors.add('选项${distractors.length + 1}');
        }

        // 随机排列选项
        final options = [correctAnswer, ...distractors];
        options.shuffle(random);
        final correctIndex = options.indexOf(correctAnswer);

        _questions.add(UnfamiliarTestQuestion(
          word: word,
          options: options,
          correctIndex: correctIndex,
        ));
      }
    }

    _questions.shuffle(random);
  }

  (String, String) _splitMeaning(String meaning) {
    final parts = meaning.split(';');
    if (parts.length >= 2) {
      return (parts[0].trim(), parts[1].trim());
    } else {
      return (meaning.trim(), meaning.trim());
    }
  }

  Future<void> _selectAnswer(int index) async {
    if (_hasAnswered) return;

    setState(() {
      _hasAnswered = true;
      _selectedAnswerIndex = index;
    });

    final isCorrect = index == _questions[_currentQuestionIndex].correctIndex;
    if (isCorrect) {
      _correctAnswers++;
    }

    // 朗读单词
    await _speakWord(_questions[_currentQuestionIndex].word);

    // 延迟后进入下一题
    await Future.delayed(Duration(seconds: isCorrect ? 1 : 2));
    _nextQuestion();
  }

  Future<void> _speakWord(String word) async {
    try {
      if (_flutterTts != null) {
        _ttsCompleter = Completer<void>();
        setState(() {
          _isPlayingTts = true;
        });
        await _flutterTts!.speak(word);
        await _ttsCompleter!.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
        _ttsCompleter = null;
      }
    } catch (_) {
      // 忽略TTS错误
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedAnswerIndex = null;
      });
    } else {
      setState(() {
        _isTestCompleted = true;
      });
    }
  }

  void _restartTest() {
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _hasAnswered = false;
      _selectedAnswerIndex = null;
      _isTestCompleted = false;
    });
    _questions.shuffle(Random());
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('不熟悉单词测试'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            '没有可测试的单词',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    if (_isTestCompleted) {
      return _buildResultPage();
    }

    return _buildTestPage();
  }

  Widget _buildTestPage() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('不熟悉单词测试 (${_currentQuestionIndex + 1}/${_questions.length})'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 进度条
              Container(
                padding: const EdgeInsets.all(16),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.orange[100],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                  minHeight: 6,
                ),
              ),

              // 题目卡片
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                                    '请选择单词的中文释义',
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
      ),
    );
  }

  Widget _buildOptionCard(UnfamiliarTestQuestion question, int index) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == question.correctIndex;
    final isWrong = _hasAnswered && isSelected && !isCorrect;
    final shouldShowCorrect = _hasAnswered && isCorrect;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;

    if (_hasAnswered) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _selectAnswer(index),
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
                  ),
                ),
              ),
              if (_hasAnswered && isCorrect)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 24,
                ),
              if (_hasAnswered && isWrong)
                Icon(
                  Icons.cancel,
                  color: Colors.red[600],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPage() {
    final accuracy = (_correctAnswers / _questions.length * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('测试结果'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          accuracy >= 80 ? Icons.celebration : Icons.thumb_up,
                          size: 64,
                          color: accuracy >= 80 ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '测试完成！',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '正确率',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$accuracy%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color:
                                accuracy >= 80 ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '答对 $_correctAnswers 题，共 ${_questions.length} 题',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restartTest,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新测试'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text('返回'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnfamiliarTestQuestion {
  final String word;
  final List<String> options;
  final int correctIndex;

  UnfamiliarTestQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}
