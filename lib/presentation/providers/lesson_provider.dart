import 'package:flutter/foundation.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/usecases/lesson_usecases.dart';

/// 课程状态管理Provider
class LessonProvider extends ChangeNotifier {
  final LessonRepository _repository;
  
  // 用例
  late final GetLessonsUseCase _getLessonsUseCase;
  late final SaveLessonsUseCase _saveLessonsUseCase;
  late final DeleteLessonsUseCase _deleteLessonsUseCase;
  late final SearchLessonsUseCase _searchLessonsUseCase;
  late final GetLessonByIdUseCase _getLessonByIdUseCase;
  late final SyncLessonsUseCase _syncLessonsUseCase;
  late final ImportLessonsUseCase _importLessonsUseCase;
  late final BatchManageLessonsUseCase _batchManageLessonsUseCase;

  LessonProvider({required LessonRepository lessonRepository})
      : _repository = lessonRepository {
    _initializeUseCases();
    _loadInitialData();
  }

  /// 初始化用例
  void _initializeUseCases() {
    _getLessonsUseCase = GetLessonsUseCase(_repository);
    _saveLessonsUseCase = SaveLessonsUseCase(_repository);
    _deleteLessonsUseCase = DeleteLessonsUseCase(_repository);
    _searchLessonsUseCase = SearchLessonsUseCase(_repository);
    _getLessonByIdUseCase = GetLessonByIdUseCase(_repository);
    _syncLessonsUseCase = SyncLessonsUseCase(_repository);
    _importLessonsUseCase = ImportLessonsUseCase(_repository);
    _batchManageLessonsUseCase = BatchManageLessonsUseCase(_repository);
  }

  // 状态变量
  List<LessonEntity> _lessons = [];
  List<LessonEntity> _filteredLessons = [];
  LessonEntity? _currentLesson;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSyncing = false;
  String _error = '';
  String _searchQuery = '';
  
  // Getters
  List<LessonEntity> get lessons => _lessons;
  List<LessonEntity> get filteredLessons => _filteredLessons;
  LessonEntity? get currentLesson => _currentLesson;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSyncing => _isSyncing;
  String get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasLessons => _lessons.isNotEmpty;
  bool get hasError => _error.isNotEmpty;
  int get totalLessons => _lessons.length;

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    await loadLessons();
  }

  /// 加载课程列表
  Future<void> loadLessons() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📚 开始加载课程列表...');
      
      final lessons = await _getLessonsUseCase();
      
      _lessons = lessons;
      _filteredLessons = lessons;
      
      print('✅ 成功加载 ${lessons.length} 个课程');
      
      // 如果有搜索查询，重新应用过滤
      if (_searchQuery.isNotEmpty) {
        await _applySearch(_searchQuery);
      }
      
    } catch (error) {
      _setError('加载课程失败: $error');
      print('❌ 加载课程失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索课程
  Future<void> searchLessons(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredLessons = _lessons;
      _isSearching = false;
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      await _applySearch(query);
    } catch (error) {
      _setError('搜索课程失败: $error');
      print('❌ 搜索课程失败: $error');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 应用搜索过滤
  Future<void> _applySearch(String query) async {
    final results = await _searchLessonsUseCase(query);
    _filteredLessons = results;
  }

  /// 清除搜索
  void clearSearch() {
    _searchQuery = '';
    _filteredLessons = _lessons;
    _isSearching = false;
    notifyListeners();
  }

  /// 获取指定课程
  Future<LessonEntity?> getLessonById(int lessonNumber) async {
    try {
      final lesson = await _getLessonByIdUseCase(lessonNumber);
      if (lesson != null) {
        _currentLesson = lesson;
        notifyListeners();
      }
      return lesson;
    } catch (error) {
      _setError('获取课程失败: $error');
      print('❌ 获取课程失败: $error');
      return null;
    }
  }

  /// 设置当前课程
  void setCurrentLesson(LessonEntity? lesson) {
    _currentLesson = lesson;
    notifyListeners();
  }

  /// 保存课程列表
  Future<bool> saveLessons(List<LessonEntity> lessons) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('💾 开始保存 ${lessons.length} 个课程...');
      
      final success = await _saveLessonsUseCase(lessons);
      
      if (success) {
        print('✅ 课程保存成功');
        // 重新加载课程列表
        await loadLessons();
        return true;
      } else {
        _setError('保存课程失败');
        return false;
      }
    } catch (error) {
      _setError('保存课程失败: $error');
      print('❌ 保存课程失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除课程
  Future<bool> deleteLessons(List<int> lessonNumbers) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🗑️ 开始删除 ${lessonNumbers.length} 个课程...');
      
      final success = await _deleteLessonsUseCase(lessonNumbers);
      
      if (success) {
        print('✅ 课程删除成功');
        // 重新加载课程列表
        await loadLessons();
        return true;
      } else {
        _setError('删除课程失败');
        return false;
      }
    } catch (error) {
      _setError('删除课程失败: $error');
      print('❌ 删除课程失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 同步课程
  Future<bool> syncLessons() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    _clearError();
    notifyListeners();
    
    try {
      print('🔄 开始同步课程...');
      
      final success = await _syncLessonsUseCase();
      
      if (success) {
        print('✅ 课程同步成功');
        // 重新加载课程列表
        await loadLessons();
        return true;
      } else {
        _setError('同步课程失败');
        return false;
      }
    } catch (error) {
      _setError('同步课程失败: $error');
      print('❌ 同步课程失败: $error');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 导入课程
  Future<bool> importLessons(String jsonString) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📥 开始导入课程...');
      
      final success = await _importLessonsUseCase(jsonString);
      
      if (success) {
        print('✅ 课程导入成功');
        // 重新加载课程列表
        await loadLessons();
        return true;
      } else {
        _setError('导入课程失败');
        return false;
      }
    } catch (error) {
      _setError('导入课程失败: $error');
      print('❌ 导入课程失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量导入课程
  Future<Map<String, dynamic>> batchImportLessons(List<LessonEntity> lessons) async {
    if (_isLoading) {
      return {
        'success': false,
        'message': '正在处理其他操作，请稍后再试',
      };
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📥 开始批量导入 ${lessons.length} 个课程...');
      
      final result = await _batchManageLessonsUseCase.importBatch(lessons);
      
      if (result['success']) {
        print('✅ 批量导入成功');
        // 重新加载课程列表
        await loadLessons();
      } else {
        _setError(result['message']);
      }
      
      return result;
    } catch (error) {
      final errorMessage = '批量导入失败: $error';
      _setError(errorMessage);
      print('❌ $errorMessage');
      
      return {
        'success': false,
        'message': errorMessage,
        'imported_count': 0,
        'duplicate_count': 0,
        'total_count': lessons.length,
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 批量删除课程
  Future<Map<String, dynamic>> batchDeleteLessons(List<int> lessonNumbers) async {
    if (_isLoading) {
      return {
        'success': false,
        'message': '正在处理其他操作，请稍后再试',
      };
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🗑️ 开始批量删除 ${lessonNumbers.length} 个课程...');
      
      final result = await _batchManageLessonsUseCase.deleteBatch(lessonNumbers);
      
      if (result['success']) {
        print('✅ 批量删除成功');
        // 重新加载课程列表
        await loadLessons();
      } else {
        _setError(result['message']);
      }
      
      return result;
    } catch (error) {
      final errorMessage = '批量删除失败: $error';
      _setError(errorMessage);
      print('❌ $errorMessage');
      
      return {
        'success': false,
        'message': errorMessage,
        'deleted_count': 0,
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 导出课程为JSON
  Future<String?> exportLessonsToJson([List<int>? lessonNumbers]) async {
    try {
      print('📤 开始导出课程...');
      
      final jsonString = await _batchManageLessonsUseCase.exportToJson(lessonNumbers);
      
      print('✅ 课程导出成功');
      return jsonString;
    } catch (error) {
      _setError('导出课程失败: $error');
      print('❌ 导出课程失败: $error');
      return null;
    }
  }

  /// 获取课程统计信息
  Map<String, dynamic> getLessonStats() {
    return {
      'total_lessons': _lessons.length,
      'filtered_lessons': _filteredLessons.length,
      'has_search': _searchQuery.isNotEmpty,
      'search_query': _searchQuery,
      'current_lesson': _currentLesson?.lesson,
      'is_loading': _isLoading,
      'is_syncing': _isSyncing,
      'has_error': _error.isNotEmpty,
    };
  }

  /// 刷新课程列表
  Future<void> refresh() async {
    await loadLessons();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _error = '';
    notifyListeners();
  }

  /// 清除所有状态
  void clearAll() {
    _lessons.clear();
    _filteredLessons.clear();
    _currentLesson = null;
    _searchQuery = '';
    _isLoading = false;
    _isSearching = false;
    _isSyncing = false;
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}