import 'dart:convert';

/// 课程模型
class Lesson {
  final int lesson;
  final String title;
  final String content;
  final List<Vocabulary> vocabulary;
  final List<Sentence> sentences;
  final List<Question> questions;

  const Lesson({
    required this.lesson,
    required this.title,
    required this.content,
    required this.vocabulary,
    required this.sentences,
    required this.questions,
  });

  /// 从JSON创建课程对象
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lesson: json['lesson'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      vocabulary: (json['vocabulary'] as List<dynamic>)
          .map((item) => Vocabulary.fromJson(item as Map<String, dynamic>))
          .toList(),
      sentences: (json['sentences'] as List<dynamic>)
          .map((item) => Sentence.fromJson(item as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>)
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 从Supabase JSON创建课程对象
  factory Lesson.fromSupabaseJson(Map<String, dynamic> json) {
    return Lesson(
      lesson: json['lesson_number'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      vocabulary: _parseVocabularyFromSupabase(json['vocabulary']),
      sentences: _parseSentencesFromSupabase(json['sentences']),
      questions: _parseQuestionsFromSupabase(json['questions']),
    );
  }

  /// 解析Supabase中的词汇数据
  static List<Vocabulary> _parseVocabularyFromSupabase(dynamic data) {
    if (data == null) return [];
    
    List<dynamic> vocabList;
    if (data is String) {
      vocabList = jsonDecode(data);
    } else if (data is List) {
      vocabList = data;
    } else {
      return [];
    }
    
    return vocabList
        .map((item) => Vocabulary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 解析Supabase中的句子数据
  static List<Sentence> _parseSentencesFromSupabase(dynamic data) {
    if (data == null) return [];
    
    List<dynamic> sentenceList;
    if (data is String) {
      sentenceList = jsonDecode(data);
    } else if (data is List) {
      sentenceList = data;
    } else {
      return [];
    }
    
    return sentenceList
        .map((item) => Sentence.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 解析Supabase中的问题数据
  static List<Question> _parseQuestionsFromSupabase(dynamic data) {
    if (data == null) return [];
    
    List<dynamic> questionList;
    if (data is String) {
      questionList = jsonDecode(data);
    } else if (data is List) {
      questionList = data;
    } else {
      return [];
    }
    
    return questionList
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'lesson': lesson,
      'title': title,
      'content': content,
      'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
      'sentences': sentences.map((s) => s.toJson()).toList(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  /// 转换为Supabase JSON格式
  Map<String, dynamic> toSupabaseJson() {
    return {
      'lesson_number': lesson,
      'title': title,
      'content': content,
      'vocabulary': jsonEncode(vocabulary.map((v) => v.toJson()).toList()),
      'sentences': jsonEncode(sentences.map((s) => s.toJson()).toList()),
      'questions': jsonEncode(questions.map((q) => q.toJson()).toList()),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// 词汇模型
class Vocabulary {
  final String word;
  final String meaning;

  const Vocabulary({
    required this.word,
    required this.meaning,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
    };
  }
}

/// 句子模型
class Sentence {
  final String text;
  final String note;

  const Sentence({
    required this.text,
    required this.note,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      text: json['text'] as String,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'note': note,
    };
  }
}

/// 问题模型
class Question {
  final String question;
  final QuestionOptions options;
  final String answer;

  const Question({
    required this.question,
    required this.options,
    required this.answer,
  });

  // 添加q getter以兼容现有代码
  String get q => question;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['q'] as String,
      options: QuestionOptions.fromJson(json['options'] as Map<String, dynamic>),
      answer: json['answer'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'q': question,
      'options': options.toJson(),
      'answer': answer,
    };
  }
}

/// 问题选项模型
class QuestionOptions {
  final String a;
  final String b;
  final String c;
  final String d;

  const QuestionOptions({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  });

  // 添加命名构造函数以支持A、B、C、D参数
  const QuestionOptions.fromOptions({
    required String A,
    required String B,
    required String C,
    required String D,
  }) : a = A, b = B, c = C, d = D;

  factory QuestionOptions.fromJson(Map<String, dynamic> json) {
    return QuestionOptions(
      a: json['A'] as String,
      b: json['B'] as String,
      c: json['C'] as String,
      d: json['D'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'A': a,
      'B': b,
      'C': c,
      'D': d,
    };
  }

  /// 获取选项映射
  Map<String, String> get optionsMap {
    return {
      'A': a,
      'B': b,
      'C': c,
      'D': d,
    };
  }

  /// 根据键获取选项文本
  String? getOptionText(String key) {
    return optionsMap[key.toUpperCase()];
  }

  /// 兼容旧代码的getOption方法
  String? getOption(String key) {
    return getOptionText(key);
  }
}
