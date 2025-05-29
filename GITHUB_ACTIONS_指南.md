# GitHub Actions Windows构建指南

## 🚀 快速开始

### 1. 准备GitHub仓库

如果还没有GitHub仓库：

```bash
# 初始化Git仓库
git init

# 添加远程仓库（替换为您的GitHub仓库地址）
git remote add origin https://github.com/您的用户名/您的仓库名.git
```

如果已有仓库，确保远程地址正确：

```bash
# 检查远程仓库
git remote -v

# 如需修改远程地址
git remote set-url origin https://github.com/您的用户名/您的仓库名.git
```

### 2. 上传代码

#### macOS/Linux用户：
```bash
./upload_to_github.sh
```

#### Windows用户：
```cmd
upload_to_github.bat
```

或者手动操作：

```bash
# 添加所有文件
git add .

# 提交更改
git commit -m "🎉 物资anticheat项目初始化"

# 推送到GitHub
git push -u origin main
```

## 🔧 触发Windows构建

### 自动触发
以下情况会自动触发构建：
- 推送代码到 `main` 或 `master` 分支
- 创建Pull Request
- 推送标签（如 `v1.0.0`）

### 手动触发
1. 访问GitHub仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build Windows App** workflow
4. 点击 **Run workflow** 按钮
5. 选择是否创建Release

## 📦 构建产物

构建完成后，会生成以下文件：

### Artifacts（构建产物）
- `material-anticheat-windows.zip` - 标准版
- `material-anticheat-portable.zip` - 便携版

### Release文件（如果创建了Release）
自动发布到GitHub Releases页面，包含：
- 应用程序文件
- 版本说明
- 使用指南

## 🏷️ 创建版本标签

创建标签会自动触发Release：

```bash
# 创建标签
git tag v1.0.0

# 推送标签
git push origin v1.0.0
```

标签命名建议：
- `v1.0.0` - 正式版本
- `v1.0.0-beta` - 测试版本
- `v1.0.0-alpha` - 内测版本

## 📊 监控构建状态

### 查看构建进度
1. 访问GitHub仓库
2. 点击 **Actions** 标签
3. 查看最新的workflow运行状态

### 构建状态说明
- 🟡 **In Progress** - 构建中
- ✅ **Success** - 构建成功
- ❌ **Failed** - 构建失败

### 查看构建日志
1. 点击具体的workflow运行
2. 展开各个步骤查看详细日志
3. 如有错误，在日志中查找错误信息

## 🛠️ 故障排除

### 常见构建错误

#### 1. Flutter版本问题
```
错误：Flutter版本不兼容
解决：检查pubspec.yaml中的Flutter版本要求
```

#### 2. 依赖包问题
```
错误：pub get失败
解决：检查pubspec.yaml中的依赖包版本
```

#### 3. 代码生成失败
```
错误：build_runner失败
解决：检查代码生成相关的注解和配置
```

### 调试技巧

1. **查看完整日志**
   - 在Actions页面下载日志文件
   - 搜索关键错误信息

2. **本地复现**
   ```bash
   # 本地测试构建过程
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   flutter analyze
   flutter build windows --release
   ```

3. **检查构建环境**
   - 确认Flutter版本兼容性
   - 验证所有依赖包可用

## ⚙️ 自定义配置

### 修改Flutter版本
编辑 `.github/workflows/windows-build.yml`：

```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # 修改为需要的版本
```

### 调整构建设置
在workflow文件中可以修改：
- 缓存策略
- 测试执行
- 产物保留时间
- Release创建条件

### 添加环境变量
如需添加密钥或配置：

1. 在GitHub仓库设置中添加Secrets
2. 在workflow中引用：
   ```yaml
   env:
     API_KEY: ${{ secrets.API_KEY }}
   ```

## 📋 最佳实践

### 代码提交
- 使用清晰的提交信息
- 定期提交小的更改
- 避免提交敏感信息

### 版本管理
- 遵循语义化版本规范
- 为重要版本创建标签
- 维护更新日志

### 构建优化
- 利用缓存减少构建时间
- 并行执行可能的步骤
- 及时清理过期的构建产物

## 🆘 获取帮助

如遇到问题：

1. **检查GitHub Actions文档**
   - [GitHub Actions官方文档](https://docs.github.com/en/actions)
   - [Flutter CI/CD指南](https://docs.flutter.dev/deployment/cd)

2. **查看社区方案**
   - GitHub上的Flutter Actions示例
   - Stack Overflow相关问题

3. **本地调试**
   - 在本地环境复现构建流程
   - 使用Flutter doctor检查环境

---

## 📞 技术支持

如需进一步帮助，请提供：
- 错误日志截图
- 构建失败的workflow链接
- 本地环境信息（flutter doctor输出） 