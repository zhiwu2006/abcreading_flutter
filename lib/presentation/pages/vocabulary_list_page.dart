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

  @override
  void initState() {
    super.initState();
    _loadUnfamiliarWords();
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

  /// 加载不熟悉单词列表
  Future<void> _loadUnfamiliarWords() async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getStringList('unfamiliar_words') ?? [];
    setState(() {
      _unfamiliarWords = words.toSet();
    });
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    return Container(
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
        ],
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
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      zh,
                      style: TextStyle(
                        fontSize: 16, // 从12扩大到16
                        color: isUnfamiliar ? Colors.orange[600] : Colors.green[700],
                        fontFamily: 'TimesNewRoman',
                        fontWeight: FontWeight.w500,
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
    super.dispose();
  }
}
