import 'dart:convert';

class WordEntity {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String partOfSpeech;
  final List<String> examples;
  final bool isLearned;
  final int difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  const WordEntity({
    required this.id,
    required this.word,
    required this.meaning,
    this.pronunciation = '',
    this.partOfSpeech = '',
    this.examples = const [],
    this.isLearned = false,
    this.difficulty = 1,
    required this.createdAt,
    required this.updatedAt,
    this.audioUrl,
    this.metadata,
  });

  // 复制构造函数
  WordEntity copyWith({
    String? id,
    String? word,
    String? meaning,
    String? pronunciation,
    String? partOfSpeech,
    List<String>? examples,
    bool? isLearned,
    int? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) {
    return WordEntity(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      examples: examples ?? this.examples,
      isLearned: isLearned ?? this.isLearned,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      audioUrl: audioUrl ?? this.audioUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // 从 JSON 创建实例
  factory WordEntity.fromJson(Map<String, dynamic> json) {
    return WordEntity(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      examples: (json['examples'] as List<dynamic>?)?.cast<String>() ?? [],
      isLearned: json['is_learned'] as bool? ?? false,
      difficulty: json['difficulty'] as int? ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      audioUrl: json['audio_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'part_of_speech': partOfSpeech,
      'examples': examples,
      'is_learned': isLearned,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'audio_url': audioUrl,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WordEntity(id: $id, word: $word, meaning: $meaning, isLearned: $isLearned)';
  }

  // 标记为已学习
  WordEntity markAsLearned() {
    return copyWith(
      isLearned: true,
      updatedAt: DateTime.now(),
    );
  }

  // 标记为未学习
  WordEntity markAsUnlearned() {
    return copyWith(
      isLearned: false,
      updatedAt: DateTime.now(),
    );
  }

  // 获取难度描述
  String get difficultyDescription {
    switch (difficulty) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      case 4:
        return '很难';
      case 5:
        return '极难';
      default:
        return '未知';
    }
  }

  // 检查是否有音频
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // 检查是否有例句
  bool get hasExamples => examples.isNotEmpty;

  // 获取第一个例句
  String get firstExample => examples.isNotEmpty ? examples.first : '';

  // 创建默认单词
  static WordEntity createDefault({
    required String word,
    required String meaning,
    String? id,
  }) {
    final now = DateTime.now();
    return WordEntity(
      id: id ?? 'word_${now.millisecondsSinceEpoch}',
      word: word,
      meaning: meaning,
      createdAt: now,
      updatedAt: now,
    );
  }
}