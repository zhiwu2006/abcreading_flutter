import 'package:flutter_english_learning/domain/entities/reading_preferences_entity.dart';
import 'package:flutter_english_learning/domain/repositories/preferences_repository.dart';
import 'package:flutter_english_learning/services/storage/local_storage_service.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final LocalStorageService _localStorage;

  PreferencesRepositoryImpl({
    LocalStorageService? localStorage,
  }) : _localStorage = localStorage ?? LocalStorageService.instance;

  @override
  Future<ReadingPreferencesEntity> getReadingPreferences() async {
    try {
      final preferences = await _localStorage.loadReadingPreferences();
      if (preferences is ReadingPreferencesEntity) {
        return preferences;
      }
      return ReadingPreferencesEntity.defaultPreferences();
    } catch (e) {
      print('❌ 获取阅读偏好设置失败: $e');
      return ReadingPreferencesEntity.defaultPreferences();
    }
  }

  @override
  Future<bool> saveReadingPreferences(ReadingPreferencesEntity preferences) async {
    try {
      await _localStorage.saveReadingPreferences(preferences);
      return true;
    } catch (e) {
      print('❌ 保存阅读偏好设置失败: $e');
      return false;
    }
  }

  @override
  Future<bool> resetReadingPreferences() async {
    try {
      final defaultPreferences = ReadingPreferencesEntity.defaultPreferences();
      await _localStorage.saveReadingPreferences(defaultPreferences);
      return true;
    } catch (e) {
      print('❌ 重置阅读偏好设置失败: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final preferences = await getReadingPreferences();
      return preferences.toJson();
    } catch (e) {
      print('❌ 获取应用设置失败: $e');
      return {};
    }
  }

  @override
  Future<bool> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final preferences = ReadingPreferencesEntity.fromJson(settings);
      return await saveReadingPreferences(preferences);
    } catch (e) {
      print('❌ 保存应用设置失败: $e');
      return false;
    }
  }

  @override
  Future<bool> clearAllPreferences() async {
    try {
      final defaultPreferences = ReadingPreferencesEntity.defaultPreferences();
      await _localStorage.saveReadingPreferences(defaultPreferences);
      return true;
    } catch (e) {
      print('❌ 清除所有偏好设置失败: $e');
      return false;
    }
  }

  @override
  Future<bool> resetToDefaults() async {
    return await resetReadingPreferences();
  }

  @override
  List<String> getAvailableFonts() {
    return [
      'System Default',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Source Sans Pro',
      'Raleway',
      'Ubuntu',
      'Nunito',
      'Poppins',
    ];
  }

  @override
  Map<String, double> getFontSizeRange() {
    return {
      'min': 12.0,
      'max': 24.0,
      'default': 16.0,
      'step': 1.0,
    };
  }
}