import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  // 默认配置（您的实际Supabase项目配置）
  static const String _defaultUrl = 'https://evbhjvxtclkzouylwwlq.supabase.co';
  static const String _defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2Ymhqdnh0Y2xrem91eWx3d2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE1NzMyODMsImV4cCI6MjA1NzE0OTI4M30.VOAAP791nIwpM_s0Gpf-ILPHWhBHKMyywQ8nm_IM9kY';
  
  // 开发环境配置
  static const bool isDevelopment = true;
  
  // 缓存的配置值
  static String? _cachedUrl;
  static String? _cachedAnonKey;
  
  /// 获取Supabase URL（支持动态配置）
  static Future<String> getUrl() async {
    if (_cachedUrl != null && _cachedUrl != _defaultUrl) {
      return _cachedUrl!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('supabase_url');
      if (savedUrl != null && savedUrl.isNotEmpty && savedUrl != _defaultUrl) {
        _cachedUrl = savedUrl;
        return savedUrl;
      }
    } catch (e) {
      print('获取保存的Supabase URL失败: $e');
    }
    
    return _defaultUrl;
  }
  
  /// 获取Supabase Anon Key（支持动态配置）
  static Future<String> getAnonKey() async {
    if (_cachedAnonKey != null && _cachedAnonKey != _defaultAnonKey) {
      return _cachedAnonKey!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('supabase_key');
      if (savedKey != null && savedKey.isNotEmpty && savedKey != _defaultAnonKey) {
        _cachedAnonKey = savedKey;
        return savedKey;
      }
    } catch (e) {
      print('获取保存的Supabase Key失败: $e');
    }
    
    return _defaultAnonKey;
  }
  
  /// 同步方法（向后兼容）
  static String get url => _cachedUrl ?? _defaultUrl;
  static String get anonKey => _cachedAnonKey ?? _defaultAnonKey;
  
  /// 检查配置是否有效
  static Future<bool> isConfigValid() async {
    final url = await getUrl();
    final key = await getAnonKey();
    
    return url.startsWith('https://') && 
           url.contains('supabase.co') &&
           key.length > 100;
  }
  
  /// 清除缓存的配置
  static void clearCache() {
    _cachedUrl = null;
    _cachedAnonKey = null;
  }
  
  /// 设置配置值（用于测试或动态配置）
  static void setConfig(String url, String anonKey) {
    _cachedUrl = url;
    _cachedAnonKey = anonKey;
  }
}
