/// 应用核心常量定义
class AppConstants {
  // 应用信息
  static const String appName = '英语阅读理解学习平台';
  static const String appVersion = '1.0.0';
  
  // Supabase配置
  static const String supabaseUrl = 'https://evbhjvxtclkzouylwwlq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2Ymhqdnh0Y2xrem91eWx3d2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE1NzMyODMsImV4cCI6MjA1NzE0OTI4M30.VOAAP791nIwpM_s0Gpf-ILPHWhBHKMyywQ8nm_IM9kY';
  
  // 数据库表名
  static const String lessonsTable = 'lessons';
  static const String progressTable = 'user_progress';
  
  // 本地存储键
  static const String learningSessionKey = 'learning_session_id';
  static const String learningProgressKey = 'learning_progress';
  static const String readingPreferencesKey = 'reading_preferences';
  
  // 缓存设置
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // 字体设置
  static const double minFontSize = 12.0;
  static const double maxFontSize = 48.0;
  static const double defaultFontSize = 24.0;
  static const double fontSizeStep = 2.0;
  
  // 可用字体列表
  static const List<String> availableFonts = [
    'times',
    'arial',
    'helvetica',
    'georgia',
    'verdana',
    'courier',
  ];
  
  // 默认设置
  static const String defaultFontFamily = 'times';
  static const bool defaultShowVocabularyHighlight = true;
  
  // 网络设置
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // 分页设置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 文件路径
  static const String defaultLessonsPath = 'assets/data/default_lessons.json';
  static const String iconsPath = 'assets/icons/';
  static const String imagesPath = 'assets/images/';
  static const String fontsPath = 'assets/fonts/';
  
  // 错误消息
  static const String networkErrorMessage = '网络连接失败，请检查网络设置';
  static const String dataLoadErrorMessage = '数据加载失败，请稍后重试';
  static const String saveErrorMessage = '保存失败，请稍后重试';
  static const String syncErrorMessage = '同步失败，请检查网络连接';
  
  // 成功消息
  static const String saveSuccessMessage = '保存成功';
  static const String syncSuccessMessage = '同步成功';
  static const String importSuccessMessage = '导入成功';
  static const String exportSuccessMessage = '导出成功';
  
  // 确认消息
  static const String deleteConfirmMessage = '确定要删除吗？此操作无法撤销。';
  static const String resetConfirmMessage = '确定要重置吗？这将清除所有数据。';
  static const String clearCacheConfirmMessage = '确定要清除缓存吗？';
  
  // 学习相关
  static const int minLessonNumber = 1;
  static const int maxLessonNumber = 999;
  static const int defaultTotalLessons = 50;
  
  // 进度计算
  static const double progressCompleteThreshold = 1.0;
  static const double progressWarningThreshold = 0.8;
  static const double progressNormalThreshold = 0.5;
  
  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
  
  // 颜色值
  static const int primaryColorValue = 0xFF2563EB;
  static const int secondaryColorValue = 0xFF10B981;
  static const int accentColorValue = 0xFFF59E0B;
  static const int errorColorValue = 0xFFEF4444;
  static const int warningColorValue = 0xFFF59E0B;
  static const int successColorValue = 0xFF10B981;
  
  // 布局尺寸
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // 响应式断点
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // 调试设置
  static const bool enableDebugMode = true;
  static const bool enablePerformanceLogging = false;
  static const bool enableNetworkLogging = true;
  
  // 版本兼容性
  static const int minSupportedVersion = 1;
  static const int currentDataVersion = 1;
  
  // 导入导出设置
  static const List<String> supportedFileExtensions = ['.json', '.txt'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const String exportFilePrefix = 'english_lessons_';
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  
  // 搜索设置
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);
  
  // 通知设置
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration shortSnackBarDuration = Duration(seconds: 1);
  static const Duration longSnackBarDuration = Duration(seconds: 5);
  
  // 性能设置
  static const int maxConcurrentOperations = 3;
  static const Duration operationTimeout = Duration(minutes: 5);
  static const int maxMemoryUsage = 256; // MB
  
  // 安全设置
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldownDuration = Duration(minutes: 15);
  static const int sessionTimeoutHours = 24;
  
  // 统计设置
  static const int maxStatisticsHistory = 100;
  static const Duration statisticsUpdateInterval = Duration(minutes: 5);
  
  // 备份设置
  static const int maxBackupFiles = 10;
  static const Duration autoBackupInterval = Duration(hours: 6);
  static const String backupFilePrefix = 'backup_';
  
  // 私有构造函数，防止实例化
  AppConstants._();
  
  /// 获取字体显示名称
  static String getFontDisplayName(String fontFamily) {
    switch (fontFamily) {
      case 'times':
        return 'Times New Roman';
      case 'arial':
        return 'Arial';
      case 'helvetica':
        return 'Helvetica';
      case 'georgia':
        return 'Georgia';
      case 'verdana':
        return 'Verdana';
      case 'courier':
        return 'Courier New';
      default:
        return fontFamily;
    }
  }
  
  /// 获取字体大小描述
  static String getFontSizeDescription(double fontSize) {
    if (fontSize <= 16) return '小';
    if (fontSize <= 20) return '较小';
    if (fontSize <= 24) return '正常';
    if (fontSize <= 28) return '较大';
    if (fontSize <= 32) return '大';
    return '超大';
  }
  
  /// 验证字体大小是否有效
  static bool isValidFontSize(double fontSize) {
    return fontSize >= minFontSize && fontSize <= maxFontSize;
  }
  
  /// 验证字体类型是否有效
  static bool isValidFontFamily(String fontFamily) {
    return availableFonts.contains(fontFamily);
  }
  
  /// 获取进度颜色值
  static int getProgressColorValue(double progress) {
    if (progress >= progressCompleteThreshold) return successColorValue;
    if (progress >= progressWarningThreshold) return warningColorValue;
    if (progress >= progressNormalThreshold) return primaryColorValue;
    return errorColorValue;
  }
  
  /// 获取文件大小描述
  static String getFileSizeDescription(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 获取时间描述
  static String getDurationDescription(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天${duration.inHours % 24}小时';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
  
  /// 检查是否为调试模式
  static bool get isDebugMode {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode && enableDebugMode;
  }
  
  /// 获取当前时间戳
  static String get currentTimestamp {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// 生成唯一ID
  static String generateUniqueId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}