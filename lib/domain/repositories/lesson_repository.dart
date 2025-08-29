import '../entities/lesson_entity.dart';

/// 课程仓库接口
abstract class LessonRepository {
  /// 获取所有课程
  Future<List<LessonEntity>> getLessons();

  /// 保存课程列表
  Future<bool> saveLessons(List<LessonEntity> lessons);

  /// 删除指定课程
  Future<bool> deleteLessons(List<int> lessonNumbers);

  /// 搜索课程
  Future<List<LessonEntity>> searchLessons(String query);

  /// 根据课程编号获取单个课程
  Future<LessonEntity?> getLessonById(int lessonNumber);

  /// 获取指定范围的课程
  Future<List<LessonEntity>> getLessonsByRange(int start, int end);

  /// 与远程数据库同步
  Future<bool> syncWithRemote();

  /// 清除本地缓存
  Future<bool> clearCache();

  /// 获取缓存信息
  Future<Map<String, dynamic>> getCacheInfo();

  /// 从JSON字符串导入课程
  Future<bool> importLessonsFromJson(String jsonString);
}