 import 'dart:convert';
import 'package:flutter_english_learning/domain/entities/word_entity.dart';

class LessonEntity {
  final String id;
  final int lesson; // 课程编号
  final String title;
  final String description;
  final List<WordEntity> words;
  final int difficulty;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final double progress;
  final String? imageUrl;
  final List<String> tags;
  final int estimatedDuration; // 预计学习时长（分钟）
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  const LessonEntity({
    required this.id,
    required this.lesson,
    required this.title,
    required this.description,
    required this.words,
    this.difficulty = 1,
    this.category = 'general',
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.progress = 0.0,
    this.imageUrl,
    this.tags = const [],
    this.estimatedDuration = 30,
    this.audioUrl,
    this.metadata,
  });

  // 复制构造函数
  LessonEntity copyWith({
    String? id,
    int? lesson,
    String? title,
    String? description,
    List<WordEntity>? words,
    int? difficulty,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    double? progress,
    String? imageUrl,
    List<String>? tags,
    int? estimatedDuration,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      lesson: lesson ?? this.lesson,
      title: title ?? this.title,
      description: description ?? this.description,
      words: words ?? this.words,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      audioUrl: audioUrl ?? this.audioUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // 从 JSON 创建实例
  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    return LessonEntity(
      id: json['id'] as String? ?? '',
      lesson: json['lesson'] as int? ?? json['lesson_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      words: (json['words'] as List<dynamic>?)
              ?.map((wordJson) => WordEntity.fromJson(wordJson as Map<String, dynamic>))
              .toList() ??
          [],
      difficulty: json['difficulty'] as int? ?? 1,
      category: json['category'] as String? ?? 'general',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      estimatedDuration: json['estimated_duration'] as int? ?? 30,
      audioUrl: json['audio_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'words': words.map((word) => word.toJson()).toList(),
      'difficulty': difficulty,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_completed': isCompleted,
      'progress': progress,
      'image_url': imageUrl,
      'tags': tags,
      'estimated_duration': estimatedDuration,
      'audio_url': audioUrl,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LessonEntity(id: $id, title: $title, words: ${words.length}, progress: $progress)';
  }

  // 获取课程统计信息
  Map<String, dynamic> get statistics {
    final completedWords = words.where((word) => word.isLearned).length;
    final totalWords = words.length;
    
    return {
      'total_words': totalWords,
      'completed_words': completedWords,
      'completion_rate': totalWords > 0 ? completedWords / totalWords : 0.0,
      'difficulty': difficulty,
      'category': category,
      'estimated_duration': estimatedDuration,
    };
  }

  // 检查课程是否可以开始学习
  bool get canStart {
    return words.isNotEmpty;
  }

  // 获取下一个未学习的单词
  WordEntity? get nextUnlearnedWord {
    try {
      return words.firstWhere((word) => !word.isLearned);
    } catch (e) {
      return null; // 所有单词都已学习
    }
  }

  // 获取课程难度描述
  String get difficultyDescription {
    switch (difficulty) {
      case 1:
        return '初级';
      case 2:
        return '中级';
      case 3:
        return '高级';
      case 4:
        return '专家';
      default:
        return '未知';
    }
  }

  // 计算实际进度（基于已学习单词数量）
  double get actualProgress {
    if (words.isEmpty) return 0.0;
    final learnedCount = words.where((word) => word.isLearned).length;
    return learnedCount / words.length;
  }

  // 检查课程是否已完成
  bool get isActuallyCompleted {
    return words.isNotEmpty && words.every((word) => word.isLearned);
  }

  // 获取课程颜色（基于类别）
  String get categoryColor {
    switch (category.toLowerCase()) {
      case 'business':
        return '#2196F3'; // 蓝色
      case 'travel':
        return '#4CAF50'; // 绿色
      case 'daily':
        return '#FF9800'; // 橙色
      case 'academic':
        return '#9C27B0'; // 紫色
      case 'technology':
        return '#607D8B'; // 蓝灰色
      default:
        return '#757575'; // 灰色
    }
  }

  // 创建默认课程
  static LessonEntity createDefault({
    required String id,
    required int lesson,
    required String title,
    String description = '',
    List<WordEntity> words = const [],
  }) {
    final now = DateTime.now();
    return LessonEntity(
      id: id,
      lesson: lesson,
      title: title,
      description: description,
      words: words,
      createdAt: now,
      updatedAt: now,
    );
  }

  // 从 Supabase 数据创建实例
  factory LessonEntity.fromSupabase(Map<String, dynamic> data) {
    return LessonEntity(
      id: data['id']?.toString() ?? '',
      lesson: _parseInt(data['lesson']) ?? _parseInt(data['lesson_number']) ?? 0,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      words: _parseWordsFromSupabase(data['words']),
      difficulty: _parseInt(data['difficulty']) ?? 1,
      category: data['category']?.toString() ?? 'general',
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updated_at']) ?? DateTime.now(),
      isCompleted: data['is_completed'] == true,
      progress: _parseDouble(data['progress']) ?? 0.0,
      imageUrl: data['image_url']?.toString(),
      tags: _parseStringList(data['tags']),
      estimatedDuration: _parseInt(data['estimated_duration']) ?? 30,
      audioUrl: data['audio_url']?.toString(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // 辅助方法：解析单词列表
  static List<WordEntity> _parseWordsFromSupabase(dynamic wordsData) {
    if (wordsData == null) return [];
    
    try {
      if (wordsData is String) {
        // 如果是 JSON 字符串，先解析
        final decoded = jsonDecode(wordsData);
        if (decoded is List) {
          return decoded
              .map((item) => WordEntity.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else if (wordsData is List) {
        // 如果已经是 List
        return wordsData
            .map((item) => WordEntity.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing words from Supabase: $e');
    }
    
    return [];
  }

  // 辅助方法：安全解析整数
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // 辅助方法：安全解析双精度浮点数
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // 辅助方法：安全解析日期时间
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 辅助方法：安全解析字符串列表
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (e) {
        // 如果不是 JSON，可能是逗号分隔的字符串
        return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }
    return [];
  }

  // 转换为 Supabase 格式
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'lesson': lesson,
      'title': title,
      'description': description,
      'words': jsonEncode(words.map((word) => word.toJson()).toList()),
      'difficulty': difficulty,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_completed': isCompleted,
      'progress': progress,
      'image_url': imageUrl,
      'tags': jsonEncode(tags),
      'estimated_duration': estimatedDuration,
      'audio_url': audioUrl,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  // 验证课程数据完整性
  bool get isValid {
    return id.isNotEmpty && 
           title.isNotEmpty && 
           words.isNotEmpty &&
           difficulty >= 1 && 
           difficulty <= 5 &&
           progress >= 0.0 && 
           progress <= 1.0;
  }

  // 获取课程学习建议
  String get learningTip {
    final completionRate = actualProgress;
    
    if (completionRate == 0.0) {
      return '开始学习这个课程，建议每天学习${(estimatedDuration / 7).ceil()}分钟';
    } else if (completionRate < 0.3) {
      return '继续加油！已完成${(completionRate * 100).toInt()}%，保持学习节奏';
    } else if (completionRate < 0.7) {
      return '进展不错！已完成${(completionRate * 100).toInt()}%，可以加快学习速度';
    } else if (completionRate < 1.0) {
      return '即将完成！已完成${(completionRate * 100).toInt()}%，坚持到底';
    } else {
      return '恭喜完成课程！可以复习巩固或挑战更高难度';
    }
  }

  // 获取推荐的下次学习时间
  DateTime get recommendedNextStudyTime {
    final now = DateTime.now();
    final completionRate = actualProgress;
    
    if (completionRate == 0.0) {
      // 新课程，建议立即开始
      return now;
    } else if (completionRate < 0.5) {
      // 进行中的课程，建议第二天学习
      return now.add(const Duration(days: 1));
    } else {
      // 接近完成的课程，建议当天完成
      return now.add(const Duration(hours: 2));
    }
  }
}