import 'package:flutter_english_learning/domain/entities/reading_preferences_entity.dart';

abstract class PreferencesRepository {
  Future<ReadingPreferencesEntity> getReadingPreferences();
  Future<bool> saveReadingPreferences(ReadingPreferencesEntity preferences);
  Future<bool> resetReadingPreferences();
  Future<Map<String, dynamic>> getAppSettings();
  Future<bool> saveAppSettings(Map<String, dynamic> settings);
  Future<bool> clearAllPreferences();
  
  // 新增缺失的方法
  Future<bool> resetToDefaults();
  List<String> getAvailableFonts();
  Map<String, double> getFontSizeRange();
}
