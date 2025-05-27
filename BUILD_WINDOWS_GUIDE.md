# Windows 构建指南

## 🚀 快速开始

### 步骤1：创建GitHub仓库
1. 访问 [GitHub](https://github.com)
2. 点击右上角的 "+" 按钮，选择 "New repository"
3. 仓库名称建议使用：`material-anticheat` 或 `物资anticheat`
4. 设置为 Public 或 Private（根据需要）
5. 点击 "Create repository"

### 步骤2：推送代码
#### 方法1：使用脚本（推荐）
1. **macOS/Linux 用户**：
   ```bash
   # 编辑 push-and-build.sh，替换仓库URL
   nano push-and-build.sh
   # 运行脚本
   ./push-and-build.sh
   ```

2. **Windows 用户**：
   ```cmd
   # 编辑 push-and-build.bat，替换仓库URL
   notepad push-and-build.bat
   # 运行脚本
   push-and-build.bat
   ```

#### 方法2：手动推送
```bash
# 替换为你的实际仓库地址
git remote add origin https://github.com/你的用户名/仓库名.git
git push -u origin main
```

### 步骤3：等待构建完成
1. 推送成功后，GitHub Actions 会自动开始构建
2. 访问你的仓库页面，点击 "Actions" 标签
3. 查看 "Build Windows Only" 工作流
4. 构建时间大约 5-10 分钟

### 步骤4：下载Windows应用
1. 构建完成后，点击对应的构建记录
2. 在 "Artifacts" 部分找到 "windows-build-only"
3. 点击下载 `物资anticheat-windows-x64.zip`
4. 解压缩文件
5. 运行 `material_anticheat.exe`

## 📋 构建特性

- ✅ 专门针对Windows平台优化
- ✅ 包含Python脚本支持
- ✅ 详细的构建日志
- ✅ 自动生成可执行文件
- ✅ 压缩包下载

## 🔧 故障排除

### 构建失败常见原因：
1. **依赖问题**：检查 `pubspec.yaml` 文件
2. **Flutter版本**：确保使用 Flutter 3.24.0
3. **代码错误**：检查 `flutter analyze` 输出

### 本地测试：
```bash
# 本地构建测试
flutter clean
flutter pub get
flutter build windows --release
```

## 📝 注意事项

- 确保你的GitHub仓库启用了Actions功能
- 构建产物会保存30天
- 推送到 main 分支会自动触发构建
- 支持手动触发构建（workflow_dispatch）

## 🆘 获取帮助

如果遇到问题：
1. 查看GitHub Actions日志
2. 检查Flutter和Dart环境
3. 确认网络连接正常
4. 验证仓库权限设置 