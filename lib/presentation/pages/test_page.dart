import 'package:flutter/material.dart';
import 'word_test_page.dart';
import 'cloze_test_page.dart';
import 'vocabulary_list_page.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '测试模块',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 欢迎区域
                _buildWelcomeSection(),
                const SizedBox(height: 32),

                // 测试选项
                const Text(
                  '选择测试类型',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
                const SizedBox(height: 16),

                // 测试卡片
                _buildTestCard(
                  title: '单词测试',
                  subtitle: '测试词汇掌握程度',
                  description: '通过选择题形式测试单词释义和用法',
                  icon: Icons.spellcheck,
                  color: Colors.blue,
                  onTap: () => _navigateToWordTest(),
                ),
                const SizedBox(height: 16),
                _buildTestCard(
                  title: '完形填空',
                  subtitle: '测试阅读理解能力',
                  description: '在文章中选择正确的单词填入空白处',
                  icon: Icons.article,
                  color: Colors.green,
                  onTap: () => _navigateToClozeTest(),
                ),
                const SizedBox(height: 16),
                _buildTestCard(
                  title: '单词列表',
                  subtitle: '查看所有课程词汇',
                  description: '按课文顺序浏览并展开释义',
                  icon: Icons.list_alt,
                  color: Colors.orange,
                  onTap: () => _navigateToVocabularyList(),
                ),
                const SizedBox(height: 32),

                // 底部统计信息
                _buildStatsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.science,
              size: 32,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '英语能力测试',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '通过多种测试方式检验学习成果',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'TimesNewRoman',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color[100]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标区域
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color[600],
              ),
            ),
            const SizedBox(width: 20),

            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color[700],
                      fontFamily: 'TimesNewRoman',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color[600],
                      fontFamily: 'TimesNewRoman',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontFamily: 'TimesNewRoman',
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: color[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.quiz,
            label: '已完成测试',
            value: '0',
            color: Colors.blue,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: '平均分数',
            value: '--',
            color: Colors.green,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.emoji_events,
            label: '最高分数',
            value: '--',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color[700],
            fontFamily: 'TimesNewRoman',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontFamily: 'TimesNewRoman',
          ),
        ),
      ],
    );
  }

  void _navigateToWordTest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WordTestPage(),
      ),
    );
  }

  void _navigateToClozeTest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ClozeTestPage(),
      ),
    );
  }

  void _navigateToVocabularyList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VocabularyListPage(),
      ),
    );
  }
}
