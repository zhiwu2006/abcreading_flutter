import 'package:flutter/material.dart';
import '../../models/lesson.dart';

class LessonPreviewDialog extends StatelessWidget {
  final List<Lesson> lessons;

  const LessonPreviewDialog({
    super.key,
    required this.lessons,
  });

  static Future<bool?> show(BuildContext context, List<Lesson> lessons) {
    return showDialog<bool>(
      context: context,
      builder: (context) => LessonPreviewDialog(lessons: lessons),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview, color: Colors.blue),
          const SizedBox(width: 8),
          Text('课程预览 (${lessons.length}个)'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '即将导入以下课程：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${lesson.lesson}',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        lesson.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '词汇: ${lesson.vocabulary.length} | 句子: ${lesson.sentences.length} | 题目: ${lesson.questions.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection('内容预览', lesson.content.length > 100 
                                ? '${lesson.content.substring(0, 100)}...'
                                : lesson.content),
                              
                              if (lesson.vocabulary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildSection('词汇示例', 
                                  lesson.vocabulary.take(3).map((v) => '${v.word}: ${v.meaning}').join(', ') +
                                  (lesson.vocabulary.length > 3 ? '...' : '')),
                              ],
                              
                              if (lesson.questions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildSection('题目示例', lesson.questions.first.q),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('确认导入'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}