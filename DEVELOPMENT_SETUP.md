# 开发环境配置

## 🛠️ 开发分支说明

### 分支结构
- `main` - 主分支，稳定版本
- `feature/v0.4-development` - v0.4.0 开发分支
- `feature/specific-feature` - 具体功能开发分支
- `hotfix/bug-fix` - 紧急修复分支

### 当前开发分支
**分支名称**: `feature/v0.4-development`
**基于版本**: v0.3.0
**目标版本**: v0.4.0

## 🚀 开发环境准备

### 1. 克隆仓库并切换分支
```bash
git clone https://github.com/zhiwu2006/abcreading_flutter.git
cd flutter_english_learning
git checkout feature/v0.4-development
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行应用
```bash
flutter run
```

### 4. 代码质量检查
```bash
flutter analyze
flutter test
```

## 📋 开发工作流

### 1. 创建功能分支
```bash
git checkout feature/v0.4-development
git pull origin feature/v0.4-development
git checkout -b feature/new-feature-name
```

### 2. 开发和提交
```bash
# 开发代码
git add .
git commit -m "feat: 添加新功能描述"
```

### 3. 合并到开发分支
```bash
git checkout feature/v0.4-development
git merge feature/new-feature-name
git push origin feature/v0.4-development
```

### 4. 发布版本
```bash
git checkout main
git merge feature/v0.4-development
git tag -a v0.4.0 -m "Release v0.4.0"
git push origin main --tags
```

## 🧪 测试指南

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/specific_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

### 测试类型
- **单元测试**: 测试单个函数或类
- **Widget 测试**: 测试 UI 组件
- **集成测试**: 测试完整功能流程

## 📝 提交规范

### 提交信息格式
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### 类型说明
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建或辅助工具变动

### 示例
```bash
git commit -m "feat(editor): 添加课程搜索功能"
git commit -m "fix(sync): 修复数据同步失败问题"
git commit -m "docs: 更新开发文档"
```

## 🔍 代码审查

### 审查清单
- [ ] 代码符合项目规范
- [ ] 功能实现正确
- [ ] 包含必要的测试
- [ ] 文档已更新
- [ ] 性能影响可接受
- [ ] 无安全问题

### 审查流程
1. 创建 Pull Request
2. 代码审查
3. 修改反馈
4. 批准合并

## 🐛 调试技巧

### Flutter 调试
```bash
# 调试模式运行
flutter run --debug

# 性能分析
flutter run --profile

# 发布模式测试
flutter run --release
```

### 常用调试工具
- Flutter Inspector
- Dart DevTools
- VS Code 调试器
- Android Studio 调试器

## 📚 开发资源

### 文档链接
- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 语言指南](https://dart.dev/guides)
- [项目架构说明](./README.md)

### 相关文件
- `DEVELOPMENT_PLAN_V0.4.md` - 开发计划
- `ISSUES_TEMPLATE.md` - Issue 模板
- `LESSON_EDITOR_FEATURES.md` - 功能说明
- `LESSON_EDITOR_GUIDE.md` - 使用指南

## 🎯 开发目标

### v0.4.0 主要目标
1. 修复已知 Bug 和性能问题
2. 添加搜索和过滤功能
3. 增强批量操作能力
4. 改善用户体验
5. 完善测试覆盖

### 质量标准
- 代码覆盖率 > 80%
- 无严重性能问题
- 用户体验流畅
- 功能稳定可靠