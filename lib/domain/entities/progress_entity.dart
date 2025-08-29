import 'dart:convert';

/// 学习进度实体类
class ProgressEntity {
  final String id;
  final String? userId;
  final String? sessionId;
  final int currentLessonIndex;
  final int currentLessonNumber;
  final int totalLessons;
  final DateTime lastAccessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgressEntity({
    required this.id,
    this.userId,
    this.sessionId,
    required this.currentLessonIndex,
    required this.currentLessonNumber,
    required this.totalLessons,
    required this.lastAccessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建新的学习进度
  factory ProgressEntity.create({
    required String id,
    String? userId,
    String? sessionId,
    int currentLessonIndex = 0,
    int currentLessonNumber = 1,
    required int totalLessons,
  }) {
    final now = DateTime.now();
    return ProgressEntity(
      id: id,
      userId: userId,
      sessionId: sessionId,
      currentLessonIndex: currentLessonIndex,
      currentLessonNumber: currentLessonNumber,
      totalLessons: totalLessons,
      lastAccessedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建进度实体
  factory ProgressEntity.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    
    return ProgressEntity(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      currentLessonIndex: json['current_lesson_index'] as int? ?? 0,
      currentLessonNumber: json['current_lesson_number'] as int? ?? 1,
      totalLessons: json['total_lessons'] as int? ?? 1,
      lastAccessedAt: json['last_accessed_at'] != null 
          ? DateTime.parse(json['last_accessed_at'] as String)
          : now,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : now,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : now,
    );
  }

  /// 从数据库记录创建进度实体
  factory ProgressEntity.fromDatabase(Map<String, dynamic> json) {
    final now = DateTime.now();
    
    return ProgressEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      currentLessonIndex: json['current_lesson_index'] as int? ?? 0,
      currentLessonNumber: json['current_lesson_number'] as int? ?? 1,
      totalLessons: json['total_lessons'] as int? ?? 1,
      lastAccessedAt: json['last_accessed_at'] != null 
          ? DateTime.parse(json['last_accessed_at'] as String)
          : now,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : now,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : now,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'current_lesson_index': currentLessonIndex,
      'current_lesson_number': currentLessonNumber,
      'total_lessons': totalLessons,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 转换为数据库JSON格式
  Map<String, dynamic> toDatabaseJson() {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'current_lesson_index': currentLessonIndex,
      'current_lesson_number': currentLessonNumber,
      'total_lessons': totalLessons,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 更新学习进度
  ProgressEntity updateProgress({
    required int lessonIndex,
    required int lessonNumber,
    int? totalLessons,
  }) {
    return copyWith(
      currentLessonIndex: lessonIndex,
      currentLessonNumber: lessonNumber,
      totalLessons: totalLessons,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 复制并更新部分字段
  ProgressEntity copyWith({
    String? id,
    String? userId,
    String? sessionId,
    int? currentLessonIndex,
    int? currentLessonNumber,
    int? totalLessons,
    DateTime? lastAccessedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      currentLessonNumber: currentLessonNumber ?? this.currentLessonNumber,
      totalLessons: totalLessons ?? this.totalLessons,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 计算学习进度百分比
  double get progressPercentage {
    if (totalLessons <= 0) return 0.0;
    return (currentLessonIndex / totalLessons).clamp(0.0, 1.0);
  }

  /// 获取剩余课程数
  int get remainingLessons {
    return (totalLessons - currentLessonIndex).clamp(0, totalLessons);
  }

  /// 检查是否已完成所有课程
  bool get isCompleted {
    return currentLessonIndex >= totalLessons;
  }

  /// 检查是否刚开始学习
  bool get isJustStarted {
    return currentLessonIndex == 0;
  }

  /// 获取学习进度状态
  String get progressStatus {
    if (isCompleted) return '已完成';
    if (isJustStarted) return '未开始';
    return '学习中';
  }

  /// 获取进度描述
  String get progressDescription {
    if (isCompleted) {
      return '恭喜！您已完成所有 $totalLessons 课的学习';
    } else if (isJustStarted) {
      return '准备开始学习，共 $totalLessons 课';
    } else {
      return '正在学习第 $currentLessonNumber 课，共 $totalLessons 课';
    }
  }

  /// 获取详细进度描述
  String get detailedProgressDescription {
    final percentage = (progressPercentage * 100).toStringAsFixed(1);
    return '$progressDescription (${percentage}%)';
  }

  /// 获取学习时长
  Duration get studyDuration {
    return DateTime.now().difference(createdAt);
  }

  /// 获取上次访问时间描述
  String get lastAccessedDescription {
    final now = DateTime.now();
    final difference = now.difference(lastAccessedAt);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return lastAccessedAt.toString().split(' ')[0]; // 显示日期
    }
  }

  /// 估算完成时间
  DateTime? get estimatedCompletionTime {
    if (isCompleted || isJustStarted) return null;
    
    final studyTime = studyDuration;
    if (studyTime.inMinutes < 1) return null;
    
    // 计算平均每课学习时间
    final averageTimePerLesson = Duration(
      milliseconds: studyTime.inMilliseconds ~/ currentLessonIndex,
    );
    
    // 估算剩余时间
    final remainingTime = Duration(
      milliseconds: averageTimePerLesson.inMilliseconds * remainingLessons,
    );
    
    return DateTime.now().add(remainingTime);
  }

  /// 获取学习统计信息
  Map<String, dynamic> get statistics {
    final studyTime = studyDuration;
    final estimatedCompletion = estimatedCompletionTime;
    
    return {
      'current_lesson': currentLessonNumber,
      'current_index': currentLessonIndex,
      'total_lessons': totalLessons,
      'progress_percentage': progressPercentage,
      'remaining_lessons': remainingLessons,
      'is_completed': isCompleted,
      'is_just_started': isJustStarted,
      'status': progressStatus,
      'study_days': studyTime.inDays,
      'study_hours': studyTime.inHours,
      'study_minutes': studyTime.inMinutes,
      'last_accessed': lastAccessedDescription,
      'estimated_completion': estimatedCompletion?.toIso8601String(),
    };
  }

  /// 验证进度数据
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('进度ID不能为空');
    }
    
    if (userId == null && sessionId == null) {
      errors.add('用户ID和会话ID不能同时为空');
    }
    
    if (currentLessonIndex < 0) {
      errors.add('当前课程索引不能小于0');
    }
    
    if (currentLessonNumber < 1) {
      errors.add('当前课程编号不能小于1');
    }
    
    if (totalLessons < 1) {
      errors.add('总课程数不能小于1');
    }
    
    if (currentLessonIndex >= totalLessons && !isCompleted) {
      errors.add('当前课程索引不能大于等于总课程数（除非已完成）');
    }
    
    if (createdAt.isAfter(DateTime.now())) {
      errors.add('创建时间不能晚于当前时间');
    }
    
    if (updatedAt.isBefore(createdAt)) {
      errors.add('更新时间不能早于创建时间');
    }
    
    return errors;
  }

  /// 检查进度数据是否有效
  bool get isValid {
    return validate().isEmpty;
  }

  /// 检查是否可以进入下一课
  bool get canGoNext {
    return currentLessonIndex < totalLessons - 1;
  }

  /// 检查是否可以回到上一课
  bool get canGoPrevious {
    return currentLessonIndex > 0;
  }

  /// 获取下一课的课程编号
  int? get nextLessonNumber {
    return canGoNext ? currentLessonNumber + 1 : null;
  }

  /// 获取上一课的课程编号
  int? get previousLessonNumber {
    return canGoPrevious ? currentLessonNumber - 1 : null;
  }

  /// 重置进度到第一课
  ProgressEntity resetToFirst() {
    return copyWith(
      currentLessonIndex: 0,
      currentLessonNumber: 1,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 跳转到指定课程
  ProgressEntity jumpToLesson(int lessonIndex, int lessonNumber) {
    if (lessonIndex < 0 || lessonIndex >= totalLessons) {
      throw ArgumentError('课程索引超出范围: $lessonIndex');
    }
    
    if (lessonNumber < 1) {
      throw ArgumentError('课程编号必须大于0: $lessonNumber');
    }
    
    return copyWith(
      currentLessonIndex: lessonIndex,
      currentLessonNumber: lessonNumber,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 标记为已完成
  ProgressEntity markAsCompleted() {
    return copyWith(
      currentLessonIndex: totalLessons,
      currentLessonNumber: totalLessons,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 获取用户类型描述
  String get userTypeDescription {
    if (userId != null) return '注册用户';
    if (sessionId != null) return '匿名用户';
    return '未知用户';
  }

  /// 检查是否为匿名用户
  bool get isAnonymousUser {
    return userId == null && sessionId != null;
  }

  /// 检查是否为注册用户
  bool get isRegisteredUser {
    return userId != null;
  }

  /// 获取用户标识符
  String get userIdentifier {
    return userId ?? sessionId ?? 'unknown';
  }

  /// 比较两个进度是否相同
  bool isSameProgress(ProgressEntity other) {
    return currentLessonIndex == other.currentLessonIndex &&
           currentLessonNumber == other.currentLessonNumber &&
           totalLessons == other.totalLessons;
  }

  /// 检查进度是否比另一个进度更新
  bool isNewerThan(ProgressEntity other) {
    return updatedAt.isAfter(other.updatedAt);
  }

  /// 合并两个进度（选择更新的那个）
  ProgressEntity mergeWith(ProgressEntity other) {
    return isNewerThan(other) ? this : other;
  }

  @override
  String toString() {
    return 'ProgressEntity('
        'id: $id, '
        'userId: $userId, '
        'sessionId: $sessionId, '
        'currentLesson: $currentLessonNumber/$totalLessons, '
        'progress: ${(progressPercentage * 100).toStringAsFixed(1)}%, '
        'status: $progressStatus, '
        'lastAccessed: $lastAccessedDescription'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProgressEntity &&
        other.id == id &&
        other.userId == userId &&
        other.sessionId == sessionId &&
        other.currentLessonIndex == currentLessonIndex &&
        other.currentLessonNumber == currentLessonNumber &&
        other.totalLessons == totalLessons &&
        other.lastAccessedAt == lastAccessedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      sessionId,
      currentLessonIndex,
      currentLessonNumber,
      totalLessons,
      lastAccessedAt,
      createdAt,
      updatedAt,
    );
  }
}