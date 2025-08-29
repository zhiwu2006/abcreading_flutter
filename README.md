# 英语阅读理解学习平台 (Flutter Android 版)

**当前版本**: 0.1.0

这是一个使用 Flutter 构建的功能丰富的英语阅读理解学习平台。它旨在通过提供结构化的课程、互动练习和个性化设置，帮助用户提升英语阅读能力。

## 核心功能

- **分课学习**: 应用内容按课程组织，每课包含一篇阅读文章。
- **多维学习模块**: 每个课程都包含四个主要部分：
  - **故事阅读**: 阅读核心文章，支持词汇点击高亮。
  - **词汇学习**: 学习与文章相关的生词及其释义。
  - **重点句子**: 分析和理解文章中的关键句型和语法。
  - **练习题**: 通过选择题检验对文章的理解程度，并提供实时评分。
- **个性化阅读体验**:
  - **字体大小调节**: 用户可以根据自己的习惯调整阅读内容的字体大小。
  - **词汇高亮**: 可以一键开启或关闭文章中生词的高亮显示。
- **课程导航**: 提供侧边栏抽屉和主页选择器，方便用户在不同课程间快速切换。
- **离线支持**: 支持在没有网络连接的情况下访问已缓存的课程内容。

## 技术架构

本项目采用现代化的 Flutter 技术栈，并遵循了清晰的分层架构模式，以实现高内聚、低耦合的代码结构。

*   **框架**: [Flutter](https://flutter.dev/)
*   **后端即服务 (BaaS)**: [Supabase](https://supabase.io/) - 用于数据持久化、同步和潜在的用户认证。
*   **状态管理**: [Provider](https://pub.dev/packages/provider) - 用于在整个应用中高效地管理和分发状态。
*   **本地存储**:
    *   [Hive](https://pub.dev/packages/hive) - 一个轻量、快速的键值对数据库，用于缓存课程数据和用户进度，实现离线访问。
    *   [SharedPreferences](https://pub.dev/packages/shared_preferences) - 用于存储用户的个性化设置。
*   **架构模式**: **分层架构 (Clean Architecture)**
    *   `lib/domain`: 包含核心业务逻辑、实体 (Entities) 和仓库接口 (Repository Interfaces)。
    *   `lib/data`: 包含仓库接口的实现、数据源 (本地和远程) 的具体逻辑。
    *   `lib/presentation`: 包含所有的 UI 组件 (页面、小部件) 和与 UI 相关的状态管理 (Providers)。
*   **网络连接**: [Connectivity Plus](https://pub.dev/packages/connectivity_plus) - 用于检测网络状态，以决定是从本地缓存加载数据还是从远程服务器同步。

## 主要依赖

- `supabase_flutter`: 与 Supabase 后端集成。
- `provider`: 状态管理。
- `hive` / `hive_flutter`: 本地数据库。
- `shared_preferences`: 简单的键值存储。
- `connectivity_plus`: 网络状态检测。
- `uuid`: 生成唯一标识符。

## 如何开始

1.  **克隆仓库**:
    ```bash
    git clone https://github.com/zhiwu2006/abcreading_flutter.git
    cd flutter_english_learning
    ```

2.  **安装依赖**:
    ```bash
    flutter pub get
    ```

3.  **配置 Supabase (如果需要)**:
    *   在 [Supabase](https://supabase.io/) 创建一个项目。
    *   在 `lib/core/config/supabase_config.dart` (或类似文件) 中填入你的 Supabase URL 和 Anon Key。

4.  **运行应用**:
    ```bash
    flutter run
    ```

## 未来可改进方向

*   **UI 组件拆分**: `lib/main.dart` 文件中的 UI 代码可以被进一步拆分到 `lib/presentation/widgets` 目录中，以提高模块化和可维护性。
*   **用户认证**: 集成完整的 Supabase 用户认证流程（注册、登录、忘记密码）。
*   **主题切换**: 添加暗黑模式/日间模式切换功能。
*   **动画与过渡**: 增加更多平滑的动画效果，提升用户体验。