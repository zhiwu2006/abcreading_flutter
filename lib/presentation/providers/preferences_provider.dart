import 'package:flutter/foundation.dart';
import '../../domain/entities/reading_preferences_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/progress_usecases.dart';

/// 阅读偏好设置状态管理Provider
class PreferencesProvider extends ChangeNotifier {
  final PreferencesRepository _repository;
  
  // 用例
  late final GetReadingPreferencesUseCase _getReadingPreferencesUseCase;
  late final SaveReadingPreferencesUseCase _saveReadingPreferencesUseCase;
  late final ResetReadingPreferencesUseCase _resetReadingPreferencesUseCase;
  late final UpdateFontSizeUseCase _updateFontSizeUseCase;
  late final UpdateFontFamilyUseCase _updateFontFamilyUseCase;
  late final ToggleVocabularyHighlightUseCase _toggleVocabularyHighlightUseCase;
  late final BatchUpdatePreferencesUseCase _batchUpdatePreferencesUseCase;
  late final GetAvailableFontsUseCase _getAvailableFontsUseCase;
  late final GetFontSizeRangeUseCase _getFontSizeRangeUseCase;

  PreferencesProvider({required PreferencesRepository preferencesRepository})
      : _repository = preferencesRepository {
    _initializeUseCases();
    _loadInitialPreferences();
  }

  /// 初始化用例
  void _initializeUseCases() {
    _getReadingPreferencesUseCase = GetReadingPreferencesUseCase(_repository);
    _saveReadingPreferencesUseCase = SaveReadingPreferencesUseCase(_repository);
    _resetReadingPreferencesUseCase = ResetReadingPreferencesUseCase(_repository);
    _updateFontSizeUseCase = UpdateFontSizeUseCase(_repository);
    _updateFontFamilyUseCase = UpdateFontFamilyUseCase(_repository);
    _toggleVocabularyHighlightUseCase = ToggleVocabularyHighlightUseCase(_repository);
    _batchUpdatePreferencesUseCase = BatchUpdatePreferencesUseCase(_repository);
    _getAvailableFontsUseCase = GetAvailableFontsUseCase(_repository);
    _getFontSizeRangeUseCase = GetFontSizeRangeUseCase(_repository);
  }

  /// 加载初始偏好设置
  Future<void> _loadInitialPreferences() async {
    await loadPreferences();
  }

  // 状态变量
  ReadingPreferencesEntity? _preferences;
  bool _isLoading = false;
  String _error = '';
  
  // Getters
  ReadingPreferencesEntity? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  bool get hasPreferences => _preferences != null;
  
  // 偏好设置相关的便捷getters
  double get fontSize => _preferences?.fontSize ?? 24.0;
  String get fontFamily => _preferences?.fontFamily ?? 'times';
  String get fontFamilyDisplay => _preferences?.fontFamilyDisplay ?? 'Times New Roman';
  bool get showVocabularyHighlight => _preferences?.showVocabularyHighlight ?? true;
  String get fontSizeDescription => _preferences?.fontSizeDescription ?? '正常';
  
  // 可用选项
  List<String> get availableFonts => _getAvailableFontsUseCase();
  Map<String, double> get fontSizeRange => _getFontSizeRangeUseCase();
  
  // 字体大小范围
  double get minFontSize => fontSizeRange['min'] ?? 12.0;
  double get maxFontSize => fontSizeRange['max'] ?? 48.0;
  double get defaultFontSize => fontSizeRange['default'] ?? 24.0;
  double get fontSizeStep => fontSizeRange['step'] ?? 2.0;

  /// 加载阅读偏好设置
  Future<void> loadPreferences() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📖 加载阅读偏好设置...');
      
      final preferences = await _getReadingPreferencesUseCase();
      _preferences = preferences;
      
      print('✅ 阅读偏好设置加载成功');
      print('字体大小: ${preferences.fontSize}');
      print('字体类型: ${preferences.fontFamilyDisplay}');
      print('生词高亮: ${preferences.showVocabularyHighlight ? '开启' : '关闭'}');
      
    } catch (error) {
      _setError('加载偏好设置失败: $error');
      print('❌ 加载偏好设置失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// 保存阅读偏好设置
  Future<bool> savePreferences(ReadingPreferencesEntity preferences) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('💾 保存阅读偏好设置...');
      
      final success = await _saveReadingPreferencesUseCase(preferences);
      
      if (success) {
        _preferences = preferences;
        print('✅ 阅读偏好设置保存成功');
        return true;
      } else {
        _setError('保存偏好设置失败');
        return false;
      }
    } catch (error) {
      _setError('保存偏好设置失败: $error');
      print('❌ 保存偏好设置失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新字体大小
  Future<bool> updateFontSize(double fontSize) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔤 更新字体大小: $fontSize');
      
      final success = await _updateFontSizeUseCase(fontSize);
      
      if (success) {
        // 更新本地状态
        if (_preferences != null) {
          _preferences = _preferences!.copyWith(fontSize: fontSize);
        }
        print('✅ 字体大小更新成功');
        return true;
      } else {
        _setError('更新字体大小失败');
        return false;
      }
    } catch (error) {
      _setError('更新字体大小失败: $error');
      print('❌ 更新字体大小失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新字体类型
  Future<bool> updateFontFamily(String fontFamily) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔤 更新字体类型: $fontFamily');
      
      final success = await _updateFontFamilyUseCase(fontFamily);
      
      if (success) {
        // 更新本地状态
        if (_preferences != null) {
          _preferences = _preferences!.copyWith(fontFamily: fontFamily);
        }
        print('✅ 字体类型更新成功');
        return true;
      } else {
        _setError('更新字体类型失败');
        return false;
      }
    } catch (error) {
      _setError('更新字体类型失败: $error');
      print('❌ 更新字体类型失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换生词高亮
  Future<bool> toggleVocabularyHighlight([bool? showHighlight]) async {
    if (_isLoading) return false;
    
    final newValue = showHighlight ?? !showVocabularyHighlight;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('💡 切换生词高亮: ${newValue ? '开启' : '关闭'}');
      
      final success = await _toggleVocabularyHighlightUseCase(newValue);
      
      if (success) {
        // 更新本地状态
        if (_preferences != null) {
          _preferences = _preferences!.copyWith(showVocabularyHighlight: newValue);
        }
        print('✅ 生词高亮设置更新成功');
        return true;
      } else {
        _setError('更新生词高亮设置失败');
        return false;
      }
    } catch (error) {
      _setError('更新生词高亮设置失败: $error');
      print('❌ 更新生词高亮设置失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量更新偏好设置
  Future<bool> batchUpdatePreferences({
    double? fontSize,
    String? fontFamily,
    bool? showVocabularyHighlight,
  }) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔄 批量更新偏好设置...');
      if (fontSize != null) print('  字体大小: $fontSize');
      if (fontFamily != null) print('  字体类型: $fontFamily');
      if (showVocabularyHighlight != null) print('  生词高亮: ${showVocabularyHighlight ? '开启' : '关闭'}');
      
      final success = await _batchUpdatePreferencesUseCase(
        fontSize: fontSize,
        fontFamily: fontFamily,
        showVocabularyHighlight: showVocabularyHighlight,
      );
      
      if (success) {
        // 重新加载偏好设置
        await loadPreferences();
        print('✅ 批量更新偏好设置成功');
        return true;
      } else {
        _setError('批量更新偏好设置失败');
        return false;
      }
    } catch (error) {
      _setError('批量更新偏好设置失败: $error');
      print('❌ 批量更新偏好设置失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 重置为默认设置
  Future<bool> resetToDefaults() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔄 重置为默认设置...');
      
      final success = await _resetReadingPreferencesUseCase();
      
      if (success) {
        // 重新加载偏好设置
        await loadPreferences();
        print('✅ 已重置为默认设置');
        return true;
      } else {
        _setError('重置设置失败');
        return false;
      }
    } catch (error) {
      _setError('重置设置失败: $error');
      print('❌ 重置设置失败: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 增加字体大小
  Future<bool> increaseFontSize() async {
    final newSize = (fontSize + fontSizeStep).clamp(minFontSize, maxFontSize);
    if (newSize == fontSize) {
      print('ℹ️ 字体大小已达到最大值');
      return false;
    }
    return await updateFontSize(newSize);
  }

  /// 减少字体大小
  Future<bool> decreaseFontSize() async {
    final newSize = (fontSize - fontSizeStep).clamp(minFontSize, maxFontSize);
    if (newSize == fontSize) {
      print('ℹ️ 字体大小已达到最小值');
      return false;
    }
    return await updateFontSize(newSize);
  }

  /// 检查是否可以增加字体大小
  bool canIncreaseFontSize() {
    return fontSize < maxFontSize;
  }

  /// 检查是否可以减少字体大小
  bool canDecreaseFontSize() {
    return fontSize > minFontSize;
  }

  /// 获取字体选项列表
  List<Map<String, String>> getFontOptions() {
    return availableFonts.map((font) {
      String displayName;
      switch (font) {
        case 'times':
          displayName = 'Times New Roman';
          break;
        case 'arial':
          displayName = 'Arial';
          break;
        case 'helvetica':
          displayName = 'Helvetica';
          break;
        case 'georgia':
          displayName = 'Georgia';
          break;
        case 'verdana':
          displayName = 'Verdana';
          break;
        case 'courier':
          displayName = 'Courier New';
          break;
        default:
          displayName = font;
      }
      
      return {
        'value': font,
        'display': displayName,
      };
    }).toList();
  }

  /// 获取字体大小选项列表
  List<Map<String, dynamic>> getFontSizeOptions() {
    final options = <Map<String, dynamic>>[];
    
    for (double size = minFontSize; size <= maxFontSize; size += fontSizeStep) {
      String description;
      if (size <= 16) {
        description = '小';
      } else if (size <= 20) {
        description = '较小';
      } else if (size <= 24) {
        description = '正常';
      } else if (size <= 28) {
        description = '较大';
      } else if (size <= 32) {
        description = '大';
      } else {
        description = '超大';
      }
      
      options.add({
        'value': size,
        'display': '${size.toInt()}px',
        'description': description,
      });
    }
    
    return options;
  }

  /// 获取偏好设置摘要
  Map<String, dynamic> getPreferencesSummary() {
    if (_preferences == null) {
      return {
        'has_preferences': false,
        'message': '偏好设置未加载',
      };
    }
    
    return {
      'has_preferences': true,
      'font_size': _preferences!.fontSize,
      'font_size_description': _preferences!.fontSizeDescription,
      'font_family': _preferences!.fontFamily,
      'font_family_display': _preferences!.fontFamilyDisplay,
      'show_vocabulary_highlight': _preferences!.showVocabularyHighlight,
      'is_valid': _preferences!.isValid,
      'created_at': _preferences!.createdAt.toIso8601String(),
      'updated_at': _preferences!.updatedAt.toIso8601String(),
    };
  }

  /// 验证字体大小是否有效
  bool isValidFontSize(double fontSize) {
    return fontSize >= minFontSize && fontSize <= maxFontSize;
  }

  /// 验证字体类型是否有效
  bool isValidFontFamily(String fontFamily) {
    return availableFonts.contains(fontFamily);
  }

  /// 获取推荐的字体大小（基于设备）
  double getRecommendedFontSize() {
    // 这里可以根据设备屏幕大小等因素来推荐合适的字体大小
    // 目前返回默认值
    return defaultFontSize;
  }

  /// 刷新偏好设置
  Future<void> refresh() async {
    await loadPreferences();
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
    _preferences = null;
    _isLoading = false;
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}