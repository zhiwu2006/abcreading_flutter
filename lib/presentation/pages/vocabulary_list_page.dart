import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/default_lessons.dart';
import '../../models/lesson.dart';
import 'unfamiliar_words_test_page.dart';

class VocabularyListPage extends StatefulWidget {
  const VocabularyListPage({super.key});

  @override
  State<VocabularyListPage> createState() => _VocabularyListPageState();
}

class _VocabularyListPageState extends State<VocabularyListPage> {
  Set<String> _unfamiliarWords = {};
  FlutterTts _flutterTts = FlutterTts();
  Set<String> _visibleMeanings = {}; // 记录哪些单词的中文含义已显示
  ScrollController _scrollController = ScrollController();
  String? _lastClickedWord; // 记录最后点击的单词
  bool _hasAutoScrolled = false; // 标记是否已自动滚动

  @override
  void initState() {
    super.initState();
    _loadUnfamiliarWords();
    _loadLastClickedWord();
    _initTts();
  }

  /// 初始化TTS
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// 朗读单词
  Future<void> _speakWord(String word) async {
    try {
      await _flutterTts.speak(word);
    } catch (e) {
      print('TTS朗读失败: $e');
    }
  }

  /// 切换中文含义显示状态
  void _toggleMeaningVisibility(String word) {
    setState(() {
      if (_visibleMeanings.contains(word)) {
        _visibleMeanings.remove(word);
      } else {
        _visibleMeanings.add(word);
      }
    });
    // 记录最后点击的单词
    print('🖱️ 用户点击了单词: $word');
    _saveLastClickedWord(word);
  }

  /// 加载不熟悉单词列表
  Future<void> _loadUnfamiliarWords() async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getStringList('unfamiliar_words') ?? [];
    setState(() {
      _unfamiliarWords = words.toSet();
    });
  }

  /// 加载单词测试正确次数
  Future<Map<String, int>> _loadWordTestCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString('word_test_counts');
    if (countsJson != null) {
      try {
        final Map<String, dynamic> counts = Map<String, dynamic>.from(
          Uri.splitQueryString(countsJson)
        );
        return counts.map((key, value) => MapEntry(key, int.tryParse(value) ?? 0));
      } catch (e) {
        print('解析单词测试次数失败: $e');
      }
    }
    return {};
  }

  /// 保存单词测试正确次数
  Future<void> _saveWordTestCounts(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = Uri(queryParameters: counts.map((key, value) => MapEntry(key, value.toString()))).query;
    await prefs.setString('word_test_counts', countsJson);
  }

  /// 更新单词测试正确次数
  Future<void> _updateWordTestCount(String word, bool isCorrect) async {
    final counts = await _loadWordTestCounts();
    if (isCorrect) {
      counts[word] = (counts[word] ?? 0) + 1;
      await _saveWordTestCounts(counts);
      
      // 如果达到3次正确，移出不熟悉列表
      if (counts[word]! >= 3) {
        setState(() {
          _unfamiliarWords.remove(word);
        });
        await _saveUnfamiliarWords();
        
        // 清除该单词的测试记录
        counts.remove(word);
        await _saveWordTestCounts(counts);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "$word" 已连续答对3次，自动移出不熟悉列表！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // 答错时重置计数
      if (counts.containsKey(word)) {
        counts.remove(word);
        await _saveWordTestCounts(counts);
      }
    }
  }

  /// 加载最后点击的单词
  Future<void> _loadLastClickedWord() async {
    final prefs = await SharedPreferences.getInstance();
    _lastClickedWord = prefs.getString('last_clicked_word');
    print('🔍 加载的单词: $_lastClickedWord');
    
    // 如果加载到的是"donated"，说明是旧数据，清除它
    if (_lastClickedWord == 'donated') {
      await prefs.remove('last_clicked_word');
      _lastClickedWord = null;
      print('🗑️ 已清除旧数据');
    }
  }

  /// 保存最后点击的单词
  Future<void> _saveLastClickedWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_clicked_word', word);
    _lastClickedWord = word;
    print('✅ 已保存单词: $word');
  }

  /// 滚动到指定单词位置
  Future<void> _scrollToWord(String word) async {
    if (_scrollController.hasClients) {
      // 等待一帧确保列表已构建
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 查找单词在列表中的精确位置
      int cumulativeIndex = 0;
      bool found = false;
      
      for (int i = 0; i < defaultLessons.length && !found; i++) {
        final lesson = defaultLessons[i];
        
        // 课程标题高度 (约50px)
        cumulativeIndex++;
        
        for (int j = 0; j < lesson.vocabulary.length; j++) {
          // 每个单词卡片高度 (约80px)
          if (lesson.vocabulary[j].word == word) {
            found = true;
            break;
          }
          cumulativeIndex++;
        }
      }
      
      if (found && _scrollController.hasClients) {
        // 计算滚动位置
        // 课程标题: 50px, 单词卡片: 80px, 间距: 8px
        final double targetOffset = cumulativeIndex * 88.0; // 平均高度
        final double maxOffset = _scrollController.position.maxScrollExtent;
        final double clampedOffset = targetOffset.clamp(0.0, maxOffset);
        
        print('📍 滚动到位置: $clampedOffset (目标单词: $word, 索引: $cumulativeIndex)');
        
        await _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        
        print('✅ 滚动完成');
      } else {
        print('❌ 未找到单词: $word');
      }
    }
  }

  /// 滚动到指定课程位置
  Future<void> _scrollToLesson(int lessonNumber) async {
    if (_scrollController.hasClients) {
      // 等待一帧确保列表已构建
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 查找课程在列表中的位置
      int cumulativeIndex = 0;
      bool found = false;
      
      for (int i = 0; i < defaultLessons.length && !found; i++) {
        final lesson = defaultLessons[i];
        if (lesson.lesson == lessonNumber) {
          found = true;
          break;
        }
        // 课程标题 + 该课程的所有单词
        cumulativeIndex += 1 + lesson.vocabulary.length;
      }
      
      if (found && _scrollController.hasClients) {
        // 计算滚动位置
        final double targetOffset = cumulativeIndex * 88.0; // 平均高度
        final double maxOffset = _scrollController.position.maxScrollExtent;
        final double clampedOffset = targetOffset.clamp(0.0, maxOffset);
        
        await _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// 显示课程导航对话框
  void _showLessonNavigator() {
    showDialog(
      context: context,
      builder: (context) => _LessonNavigatorDialog(
        lessons: defaultLessons,
        onLessonSelected: (lessonNumber) {
          Navigator.of(context).pop();
          _scrollToLesson(lessonNumber);
        },
      ),
    );
  }

  /// 清除最后点击的单词记录
  Future<void> _clearLastClickedWord() async {
    // 显示确认对话框
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除定位记录'),
        content: Text('确定要清除当前记录的单词"$_lastClickedWord"吗？\n\n清除后下次打开将不会自动定位。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: const Text('清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_clicked_word');
      setState(() {
        _lastClickedWord = null;
        _hasAutoScrolled = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 定位记录已清除'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 保存不熟悉单词列表
  Future<void> _saveUnfamiliarWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unfamiliar_words', _unfamiliarWords.toList());
  }

  /// 切换单词的熟悉状态
  Future<void> _toggleWordFamiliarity(String word) async {
    setState(() {
      if (_unfamiliarWords.contains(word)) {
        _unfamiliarWords.remove(word);
      } else {
        _unfamiliarWords.add(word);
      }
    });
    await _saveUnfamiliarWords();

    final isUnfamiliar = _unfamiliarWords.contains(word);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isUnfamiliar ? '已标记为不熟悉单词' : '已移除不熟悉标记'),
        duration: const Duration(seconds: 1),
        backgroundColor: isUnfamiliar ? Colors.orange : Colors.green,
      ),
    );
  }

  /// 导航到不熟悉单词测试
  void _navigateToUnfamiliarWordsTest() {
    if (_unfamiliarWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无不熟悉单词，请先标记一些单词'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnfamiliarWordsTestPage(
          unfamiliarWords: _unfamiliarWords.toList(),
          onTestResult: _updateWordTestCount,
        ),
      ),
    ).then((_) {
      // 测试完成后重新加载不熟悉单词列表
      _loadUnfamiliarWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 页面构建完成后自动滚动到上次位置（仅首次）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoScrolled && _lastClickedWord != null && _scrollController.hasClients) {
        print('🎯 开始自动滚动到单词: $_lastClickedWord');
        _hasAutoScrolled = true;
        _scrollToWord(_lastClickedWord!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '单词列表',
          style: TextStyle(
            fontFamily: 'TimesNewRoman',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_lastClickedWord != null) ...[
            GestureDetector(
              onTap: () => _scrollToWord(_lastClickedWord!),
              onLongPress: () => _clearLastClickedWord(),
              child: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: null, // 由GestureDetector处理
                tooltip: '点击定位到上次查看的单词，长按清除记录',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearLastClickedWord,
              tooltip: '清除定位记录',
            ),
          ],
          if (_unfamiliarWords.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_unfamiliarWords.length}'),
                child: const Icon(Icons.quiz),
              ),
              onPressed: _navigateToUnfamiliarWordsTest,
              tooltip: '不熟悉单词测试',
            ),
        ],
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
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: _buildLessonSections(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLessonSections() {
    final widgets = <Widget>[];
    for (final lesson in defaultLessons) {
      widgets.add(_buildLessonHeader(lesson));
      for (final vocab in lesson.vocabulary) {
        widgets.add(_buildVocabTile(lesson, vocab));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildLessonHeader(Lesson lesson) {
    return GestureDetector(
      onTap: _showLessonNavigator,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.orange[600], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lesson ${lesson.lesson}: ${lesson.title}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontFamily: 'TimesNewRoman',
                ),
              ),
            ),
            Icon(
              Icons.navigation,
              color: Colors.orange[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '导航',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabTile(Lesson lesson, Vocabulary vocab) {
    final parts = _splitMeaning(vocab.meaning);
    final eng = parts.$1;
    final zh = parts.$2;
    final isUnfamiliar = _unfamiliarWords.contains(vocab.word);

    return Dismissible(
      key: Key('${lesson.lesson}_${vocab.word}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: isUnfamiliar ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnfamiliar ? Icons.check_circle : Icons.bookmark_add,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isUnfamiliar ? '移除标记' : '标记不熟悉',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _toggleWordFamiliarity(vocab.word);
        return false; // 不实际删除卡片，只是触发动画
      },
      child: Card(
        elevation: isUnfamiliar ? 2 : 0,
        color: isUnfamiliar ? Colors.orange[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnfamiliar ? Colors.orange[300]! : Colors.grey[200]!,
            width: isUnfamiliar ? 2 : 1,
          ),
        ),
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Text(
                    'L${lesson.lesson}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isUnfamiliar) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.bookmark,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                ],
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    vocab.word,
                    style: TextStyle(
                      fontSize: 24, // 从18扩大到24
                      fontWeight: FontWeight.w700,
                      color: isUnfamiliar ? Colors.orange[800] : Colors.black87,
                      fontFamily: 'TimesNewRoman',
                    ),
                  ),
                ),
                // 发音按钮
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  onPressed: () => _speakWord(vocab.word),
                  tooltip: '朗读单词',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (zh.isNotEmpty && zh != eng)
                  GestureDetector(
                    onTap: () => _toggleMeaningVisibility(vocab.word),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _visibleMeanings.contains(vocab.word) 
                            ? Colors.green[50] 
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _visibleMeanings.contains(vocab.word) 
                              ? Colors.green[200]! 
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _visibleMeanings.contains(vocab.word) ? zh : '点击显示',
                        style: TextStyle(
                          fontSize: 16,
                          color: _visibleMeanings.contains(vocab.word)
                              ? (isUnfamiliar ? Colors.orange[600] : Colors.green[700])
                              : Colors.grey[600],
                          fontFamily: 'TimesNewRoman',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: null, // 移除subtitle，因为中文含义已经移到右侧
            children: [
              _buildDefinitionRow('英文释义', eng, Colors.indigo),
              const SizedBox(height: 8),
              _buildDefinitionRow('中文释义', zh, Colors.green),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefinitionRow(String label, String value, MaterialColor color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color[200]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
              fontFamily: 'TimesNewRoman',
            ),
          ),
        ),
      ],
    );
  }

  /// 分号切分释义：返回(英文, 中文)
  /// - 当仅有一段时，英文与中文均为该段
  (String, String) _splitMeaning(String meaning) {
    final parts = meaning.split(';');
    if (parts.length >= 2) {
      final eng = parts[0].trim();
      final zh = parts[1].trim();
      return (eng, zh);
    } else {
      final only = meaning.trim();
      return (only, only);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }
}

/// 课程导航对话框
class _LessonNavigatorDialog extends StatefulWidget {
  final List<Lesson> lessons;
  final Function(int lessonNumber) onLessonSelected;

  const _LessonNavigatorDialog({
    required this.lessons,
    required this.onLessonSelected,
  });

  @override
  State<_LessonNavigatorDialog> createState() => _LessonNavigatorDialogState();
}

class _LessonNavigatorDialogState extends State<_LessonNavigatorDialog> {
  late ScrollController _scrollController;
  int _selectedLesson = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '课程导航',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'TimesNewRoman',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // 当前选择显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '当前选择: Lesson $_selectedLesson',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // 课程列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: widget.lessons.length,
                itemBuilder: (context, index) {
                  final lesson = widget.lessons[index];
                  final isSelected = lesson.lesson == _selectedLesson;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLesson = lesson.lesson;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange[200] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.orange[400]! : Colors.orange[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange[600] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${lesson.lesson}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lesson ${lesson.lesson}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.orange[800] : Colors.orange[700],
                                    ),
                                  ),
                                  Text(
                                    lesson.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.orange[700] : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${lesson.vocabulary.length}词',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: Colors.orange[600],
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onLessonSelected(_selectedLesson),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '导航到课程',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
