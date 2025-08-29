import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';
import '../services/supabase_service.dart';
import '../data/default_lessons.dart';
import '../core/config/supabase_config.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  // 课程相关状态
  List<Lesson> _lessons = [];
  int _currentLessonIndex = 0;
  bool _isLoading = false;
  String? _error;
  
  // 阅读偏好设置
  int _fontSize = 16;
  bool _showVocabularyHighlight = true;
  
  // 学习进度
  Map<int, Map<String, dynamic>> _progressData = {};
  Map<int, Map<int, String>> _selectedAnswers = {};
  Map<int, bool> _showResults = {};
  Map<int, int> _scores = {};
  
  // 统计信息
  Map<String, dynamic> _statistics = {};
  
  // Getters
  List<Lesson> get lessons => _lessons;
  int get currentLessonIndex => _currentLessonIndex;
  Lesson get currentLesson => _lessons.isNotEmpty ? _lessons[_currentLessonIndex] : defaultLessons[0];
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get fontSize => _fontSize;
  bool get showVocabularyHighlight => _showVocabularyHighlight;
  
  Map<int, Map<int, String>> get selectedAnswers => _selectedAnswers;
  Map<int, bool> get showResults => _showResults;
  Map<int, int> get scores => _scores;
  Map<String, dynamic> get statistics => _statistics;
  
  // 初始化应用
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // 初始化Supabase
      await SupabaseService.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      
      // 尝试匿名登录
      if (!_supabaseService.isUserSignedIn()) {
        await _supabaseService.signInAnonymously();
      }
      
      // 加载本地偏好设置
      await _loadLocalPreferences();
      
      // 加载课程数据
      await _loadLessons();
      
      // 加载学习进度
      await _loadProgress();
      
      // 加载统计信息
      await _loadStatistics();
      
      _error = null;
    } catch (e) {
      _error = '初始化失败: $e';
      // 使用默认数据作为后备
      _lessons = defaultLessons;
    } finally {
      _setLoading(false);
    }
  }
  
  // 加载课程数据
  Future<void> _loadLessons() async {
    try {
      final remoteLessons = await _supabaseService.getLessons();
      if (remoteLessons.isNotEmpty) {
        _lessons = remoteLessons;
      } else {
        // 如果远程没有数据，使用默认数据
        _lessons = defaultLessons;
      }
    } catch (e) {
      print('加载课程失败，使用默认数据: $e');
      _lessons = defaultLessons;
    }
  }
  
  // 加载本地偏好设置
  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getInt('fontSize') ?? 16;
      _showVocabularyHighlight = prefs.getBool('showVocabularyHighlight') ?? true;
      
      // 尝试从Supabase加载偏好设置
      final userId = _supabaseService.getCurrentUserId();
      if (userId != null) {
        final remotePrefs = await _supabaseService.getPreferences(
          userId: userId,
        );
        
        if (remotePrefs != null) {
          _fontSize = remotePrefs['fontSize'] ?? _fontSize;
          _showVocabularyHighlight = remotePrefs['showVocabularyHighlight'] ?? _showVocabularyHighlight;
        }
      }
      
    } catch (e) {
      print('加载偏好设置失败: $e');
    }
  }
  
  // 加载学习进度
  Future<void> _loadProgress() async {
    try {
      for (final lesson in _lessons) {
        final progress = await _supabaseService.getProgress(
          lessonNumber: lesson.lesson,
        );
        
        if (progress != null) {
          _progressData[lesson.lesson] = progress;
          _selectedAnswers[lesson.lesson] = Map<int, String>.from(progress['selectedAnswers'] ?? {});
          _showResults[lesson.lesson] = progress['showResults'] ?? false;
          _scores[lesson.lesson] = progress['score'] ?? 0;
        }
      }
    } catch (e) {
      print('加载学习进度失败: $e');
    }
  }
  
  // 加载统计信息
  Future<void> _loadStatistics() async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      if (userId != null) {
        _statistics = await _supabaseService.getStatistics(
          userId: userId,
        );
      } else {
        _statistics = {
          'total_lessons': _lessons.length,
          'completed_lessons': 0,
          'completion_rate': 0,
        };
      }
    } catch (e) {
      print('加载统计信息失败: $e');
      _statistics = {
        'total_lessons': _lessons.length,
        'completed_lessons': 0,
        'completion_rate': 0,
      };
    }
  }
  
  // 设置当前课程
  void setCurrentLessonIndex(int index) {
    if (index >= 0 && index < _lessons.length) {
      _currentLessonIndex = index;
      notifyListeners();
    }
  }
  
  // 更新字体大小
  Future<void> updateFontSize(int newSize) async {
    _fontSize = newSize;
    notifyListeners();
    
    // 保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', newSize);
    
    // 保存到Supabase
    await _savePreferencesToSupabase();
  }
  
  // 更新词汇高亮设置
  Future<void> updateVocabularyHighlight(bool show) async {
    _showVocabularyHighlight = show;
    notifyListeners();
    
    // 保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showVocabularyHighlight', show);
    
    // 保存到Supabase
    await _savePreferencesToSupabase();
  }
  
  // 保存偏好设置到Supabase
  Future<void> _savePreferencesToSupabase() async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      if (userId != null) {
        await _supabaseService.savePreferences(
          userId: userId,
          preferences: {
            'fontSize': _fontSize,
            'showVocabularyHighlight': _showVocabularyHighlight,
          },
        );
      }
    } catch (e) {
      print('保存偏好设置到Supabase失败: $e');
    }
  }
  
  // 选择答案
  void selectAnswer(int lessonNumber, int questionIndex, String answer) {
    if (!_selectedAnswers.containsKey(lessonNumber)) {
      _selectedAnswers[lessonNumber] = {};
    }
    _selectedAnswers[lessonNumber]![questionIndex] = answer;
    notifyListeners();
  }
  
  // 提交测试
  Future<void> submitQuiz(int lessonNumber) async {
    final lesson = _lessons.firstWhere((l) => l.lesson == lessonNumber);
    final answers = _selectedAnswers[lessonNumber] ?? {};
    
    int score = 0;
    for (int i = 0; i < lesson.questions.length; i++) {
      if (answers[i] == lesson.questions[i].answer) {
        score++;
      }
    }
    
    _scores[lessonNumber] = score;
    _showResults[lessonNumber] = true;
    notifyListeners();
    
    // 保存进度到Supabase
    await _saveProgressToSupabase(lessonNumber);
    
    // 更新统计信息
    await _loadStatistics();
  }
  
  // 重置测试
  void resetQuiz(int lessonNumber) {
    _selectedAnswers[lessonNumber]?.clear();
    _showResults[lessonNumber] = false;
    _scores[lessonNumber] = 0;
    notifyListeners();
  }
  
  // 保存进度到Supabase
  Future<void> _saveProgressToSupabase(int lessonNumber) async {
    try {
      final progressData = {
        'selectedAnswers': _selectedAnswers[lessonNumber] ?? {},
        'showResults': _showResults[lessonNumber] ?? false,
        'score': _scores[lessonNumber] ?? 0,
        'completedAt': DateTime.now().toIso8601String(),
      };
      
      await _supabaseService.saveProgress(
        lessonNumber: lessonNumber,
        progress: progressData,
      );
    } catch (e) {
      print('保存进度到Supabase失败: $e');
    }
  }
  
  // 获取课程的选中答案
  Map<int, String> getLessonAnswers(int lessonNumber) {
    return _selectedAnswers[lessonNumber] ?? {};
  }
  
  // 获取课程是否显示结果
  bool getLessonShowResults(int lessonNumber) {
    return _showResults[lessonNumber] ?? false;
  }
  
  // 获取课程得分
  int getLessonScore(int lessonNumber) {
    return _scores[lessonNumber] ?? 0;
  }
  
  // 刷新数据
  Future<void> refresh() async {
    await initialize();
  }
  
  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}