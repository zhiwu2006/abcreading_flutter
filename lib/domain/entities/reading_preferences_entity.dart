class ReadingPreferencesEntity {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final String theme;
  final bool autoScroll;
  final double scrollSpeed;
  final bool highlightWords;
  final String backgroundColor;
  final String textColor;

  const ReadingPreferencesEntity({
    this.fontSize = 16.0,
    this.fontFamily = 'System',
    this.lineHeight = 1.5,
    this.theme = 'light',
    this.autoScroll = false,
    this.scrollSpeed = 1.0,
    this.highlightWords = true,
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#000000',
  });

  factory ReadingPreferencesEntity.fromJson(Map<String, dynamic> json) {
    return ReadingPreferencesEntity(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontFamily: json['fontFamily'] as String? ?? 'System',
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
      theme: json['theme'] as String? ?? 'light',
      autoScroll: json['autoScroll'] as bool? ?? false,
      scrollSpeed: (json['scrollSpeed'] as num?)?.toDouble() ?? 1.0,
      highlightWords: json['highlightWords'] as bool? ?? true,
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      textColor: json['textColor'] as String? ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'theme': theme,
      'autoScroll': autoScroll,
      'scrollSpeed': scrollSpeed,
      'highlightWords': highlightWords,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
    };
  }

  ReadingPreferencesEntity copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    String? theme,
    bool? autoScroll,
    double? scrollSpeed,
    bool? highlightWords,
    String? backgroundColor,
    String? textColor,
  }) {
    return ReadingPreferencesEntity(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
      autoScroll: autoScroll ?? this.autoScroll,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      highlightWords: highlightWords ?? this.highlightWords,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  static ReadingPreferencesEntity defaultPreferences() {
    return const ReadingPreferencesEntity();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingPreferencesEntity &&
        other.fontSize == fontSize &&
        other.fontFamily == fontFamily &&
        other.lineHeight == lineHeight &&
        other.theme == theme &&
        other.autoScroll == autoScroll &&
        other.scrollSpeed == scrollSpeed &&
        other.highlightWords == highlightWords &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      fontFamily,
      lineHeight,
      theme,
      autoScroll,
      scrollSpeed,
      highlightWords,
      backgroundColor,
      textColor,
    );
  }

  @override
  String toString() {
    return 'ReadingPreferencesEntity('
        'fontSize: $fontSize, '
        'fontFamily: $fontFamily, '
        'theme: $theme'
        ')';
  }
}