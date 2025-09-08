# 代码结构快速定位指南

## 🎯 目的

这个文档帮助开发者快速定位代码中的特定功能和组件，避免在大型文件中花费过多时间搜索。

## 📁 项目结构概览

```
lib/
├── main.dart                           # 主应用入口 (2900+ 行)
├── models/                             # 数据模型
│   └── lesson.dart                     # 课程数据模型
├── services/                           # 服务层
│   ├── lesson_manager_service.dart     # 课程管理服务
│   ├── tts_service.dart               # 语音朗读服务
│   └── supabase_service.dart          # 数据库服务
├── presentation/                       # 表现层
│   ├── pages/                         # 页面组件
│   │   ├── lesson_editor_page.dart    # 课程编辑器
│   │   └── lesson_detail_editor_page.dart # 课程详情编辑
│   └── widgets/                       # 可复用组件
└── data/                              # 数据层
    └── default_lessons.dart           # 默认课程数据
```

## 🔍 main.dart 文件结构 (关键定位)

### 应用入口和配置 (1-100行)
```dart
// 应用启动和初始化
void main() async                       // 第33行
class EnglishLearningApp               // 第70行
class ReadingPreferences               // 第95行
```

### 主页面组件 (100-600行)
```dart
class HomePage extends StatefulWidget   // 第120行
class _HomePageState                   // 第126行
  - _initApp()                         // 第150行 - 应用初始化
  - _loadProgress()                    // 第160行 - 加载学习进度
  - _saveProgress()                    // 第180行 - 保存学习进度
```

### 侧边栏和设置 (600-1200行)
```dart
_buildDrawer()                         // 第400行 - 侧边栏构建
_buildLessonSelector()                 // 第600行 - 课程选择器
class ReadingSettings                  // 第800行 - 阅读设置组件
  - _buildFontSizeSettings()           // 第900行 - 字体大小设置
  - _buildFontFamilySettings()         // 第950行 - 字体样式设置
```

### 课程内容组件 (1200-2600行)
```dart
class LessonContent                    // 第1200行 - 课程内容主组件
class _LessonContentState              // 第1220行
  - _buildStoryTab()                   // 第1400行 - 故事阅读标签页
  - _showFullScreenReading()           // 第1500行 - 🎯 全屏阅读功能
  - _buildClickableContent()           // 第1600行 - 可点击文本内容
  - _buildClickableParagraph()         // 第1700行 - 🎯 单词点击处理
  - _buildVocabularyTab()              // 第1900行 - 词汇学习标签页
  - _buildSentencesTab()               // 第2100行 - 重点句子标签页
  - _buildQuizTab()                    // 第2300行 - 练习题标签页
```

### 辅助方法 (2600-2900行)
```dart
// 语音和交互方法
_speakFullStory()                      // 第2630行 - 朗读全文
_speakWord()                           // 第2635行 - 朗读单词
_showWordMeaning()                     // 第2640行 - 🎯 单词释义弹窗
_showWordLookupDialog()                // 第2750行 - 🎯 在线查词对话框
_openOnlineDictionary()                // 第2850行 - 🎯 打开在线词典

// 测试和交互方法
_submitQuiz()                          // 第2900行 - 提交测试答案
_resetQuiz()                           // 第2950行 - 重置测试
```

## 🎨 UI 样式和主题定位

### 颜色主题
```dart
// 主要颜色 (第80-90行)
primarySwatch: Colors.blue
seedColor: Color(0xFF3B82F6)          // 主蓝色

// AppBar 颜色 (第400行左右)
backgroundColor: Color(0xFF3B82F6)     // 标题栏背景

// 全屏阅读背景 (第1550行左右) 🎯
color: Colors.white                    // 白色背景 (已修改)
// 之前是: Color(0xFFF5ECD8)          // Sepia 护眼色

// 卡片和容器背景
Color(0xFFF8FAFC)                     // 浅灰背景
Colors.blue[50]                       // 浅蓝背景
Colors.green[50]                      // 浅绿背景
```

### 字体设置
```dart
// 默认字体 (第85行)
fontFamily: 'TimesNewRoman'

// 字体大小设置 (第900行左右)
fontSize: readingPreferences.fontSize.toDouble()
```

## 🔧 功能模块快速定位

### 📖 阅读相关功能
| 功能 | 位置 | 关键方法 |
|------|------|----------|
| 全屏阅读 | 1500-1600行 | `_showFullScreenReading()` |
| 单词点击 | 1700-1800行 | `_buildClickableParagraph()` |
| 单词长按释义 | 2640-2750行 | `_showWordMeaning()` |
| 在线查词 | 2750-2900行 | `_showWordLookupDialog()` |
| 词汇高亮 | 1800-1900行 | `_buildVocabularyHighlightSection()` |

### 🎵 语音功能
| 功能 | 位置 | 关键方法 |
|------|------|----------|
| 朗读全文 | 2630行 | `_speakFullStory()` |
| 朗读单词 | 2635行 | `_speakWord()` |
| 朗读词汇 | 2760行 | `_speakVocabulary()` |

### 📝 测试功能
| 功能 | 位置 | 关键方法 |
|------|------|----------|
| 练习题显示 | 2300-2500行 | `_buildQuizTab()` |
| 提交答案 | 2900行 | `_submitQuiz()` |
| 重置测试 | 2950行 | `_resetQuiz()` |

### ⚙️ 设置功能
| 功能 | 位置 | 关键方法 |
|------|------|----------|
| 字体大小 | 900-950行 | `_buildFontSizeSettings()` |
| 字体样式 | 950-1000行 | `_buildFontFamilySettings()` |
| 词汇高亮 | 1000-1050行 | `_buildVocabularyHighlightSettings()` |

## 🔍 快速搜索技巧

### 按功能搜索
```bash
# 搜索全屏相关
grep -n "fullscreen\|全屏\|FullScreen" lib/main.dart

# 搜索颜色相关
grep -n "Color\|backgroundColor\|color:" lib/main.dart

# 搜索字体相关
grep -n "fontSize\|fontFamily\|TextStyle" lib/main.dart

# 搜索单词点击相关
grep -n "GestureDetector\|onTap\|onLongPress" lib/main.dart
```

### 按组件搜索
```bash
# 搜索特定组件
grep -n "class.*Widget\|Widget.*build" lib/main.dart

# 搜索方法定义
grep -n "void _\|Future<.*> _" lib/main.dart

# 搜索状态管理
grep -n "setState\|State<" lib/main.dart
```

## 📋 常见修改场景

### 🎨 UI 样式修改
1. **修改主题颜色**: 搜索 `Color(0xFF` 或 `Colors.blue`
2. **修改字体大小**: 搜索 `fontSize` 或 `readingPreferences.fontSize`
3. **修改背景色**: 搜索 `backgroundColor` 或 `color:`
4. **修改圆角**: 搜索 `BorderRadius.circular`

### 🔧 功能修改
1. **修改单词点击**: 定位到 `_buildClickableParagraph()` (1700行)
2. **修改全屏阅读**: 定位到 `_showFullScreenReading()` (1500行)
3. **修改语音功能**: 搜索 `ttsService` 或 `_speak`
4. **修改测试逻辑**: 定位到 `_submitQuiz()` (2900行)

### 📱 交互修改
1. **修改手势**: 搜索 `GestureDetector` 或 `onTap`
2. **修改对话框**: 搜索 `showDialog` 或 `AlertDialog`
3. **修改导航**: 搜索 `Navigator` 或 `MaterialPageRoute`
4. **修改提示**: 搜索 `SnackBar` 或 `ScaffoldMessenger`

## 🚀 开发效率提升建议

### 1. 代码分割
- **建议**: 将 main.dart 拆分为多个文件
- **优先级**: 高
- **实施**: 提取 LessonContent 为独立组件

### 2. 添加代码注释
- **建议**: 为关键方法添加详细注释
- **优先级**: 中
- **实施**: 标记功能区域和重要逻辑

### 3. 创建常量文件
- **建议**: 提取颜色、字体等常量
- **优先级**: 中
- **实施**: 创建 constants.dart 文件

### 4. 使用代码折叠
- **建议**: 在 IDE 中使用代码折叠功能
- **优先级**: 低
- **实施**: 添加 `// region` 注释

## 📝 维护清单

### 定期更新 (每次重大修改后)
- [ ] 更新行号引用
- [ ] 添加新功能的定位信息
- [ ] 检查搜索关键词的有效性
- [ ] 更新常见修改场景

### 代码重构时
- [ ] 更新文件结构图
- [ ] 重新标记关键方法位置
- [ ] 更新搜索技巧
- [ ] 验证快速定位的准确性

---

**最后更新**: 2025年1月
**维护者**: 开发团队
**版本**: v0.4.0-dev
## 🎨
 UI优化记录

### TabBar响应式优化 (v0.3.1)
**位置**: 第2640-2700行
**方法**: `_buildCompactTab(IconData icon, String text)`

**功能特点**:
- 响应式布局：根据屏幕宽度自动调整显示模式
- 高度优化：从48px缩减到40px，节省17%空间
- 三种显示模式：
  - 超窄屏：仅图标
  - 窄屏：图标+简化文字
  - 宽屏：图标+完整文字

**搜索关键词**: `COMPACT_TAB`, `响应式标签`, `_buildCompactTab`

**使用位置**: 第1715行TabBar组件中

### 离线字典功能 (v0.3.1)
**位置**: `lib/services/dictionary_service.dart`
**方法**: `DictionaryService.lookupWord(String word)`

**功能特点**:
- 基于Oxford 3000和CET-4/6词汇
- 支持词形变化匹配（复数、过去式、进行时等）
- 包含音标、中文释义、词性、学习标签
- 完全离线，无网络依赖

**搜索关键词**: `DICTIONARY`, `离线字典`, `DictionaryService`

**集成位置**: 第2680行 `_showWordMeaning` 方法中