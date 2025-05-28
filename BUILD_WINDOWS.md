# Windows 应用构建指南

本文档介绍如何为 Flutter 物资防作弊应用构建 Windows EXE 文件。

## 方法一：使用 GitHub Actions（推荐）

我们已经为你配置了 GitHub Actions 自动构建。每次提交代码到 main 分支时，会自动构建 Windows 应用。

### 使用步骤：

1. **推送代码到 GitHub**：
   ```bash
   git add .
   git commit -m "Update app"
   git push origin main
   ```

2. **查看构建状态**：
   - 访问你的 GitHub 仓库
   - 点击 "Actions" 标签
   - 查看 "Build Windows EXE" 工作流

3. **下载构建文件**：
   - 构建完成后，在 Actions 页面下载 `windows-exe` 文件
   - 解压得到可执行的 Windows 应用

### 创建正式发布：

1. **创建版本标签**：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **自动发布**：
   - GitHub Actions 会自动创建一个 Release
   - Windows 应用会作为附件上传到 Release

## 方法二：使用 Docker（本地构建）

如果你想在 macOS 上本地构建 Windows 应用，可以使用 Docker。

### 前提条件：

1. **安装 Docker Desktop**：
   - 下载：https://www.docker.com/products/docker-desktop
   - 启动 Docker Desktop

### 构建步骤：

1. **运行构建脚本**：
   ```bash
   ./build-windows.sh
   ```

2. **等待构建完成**：
   - 脚本会自动下载 Windows 容器
   - 安装 Flutter 和依赖
   - 构建 Windows 应用

3. **获取构建文件**：
   - 构建文件在 `windows-build/` 目录
   - 压缩包：`物资anticheat-windows.zip`

## 方法三：在 Windows 机器上构建

如果你有 Windows 机器或虚拟机，可以直接构建：

### 前提条件：

1. **安装 Flutter**：
   - 下载：https://docs.flutter.dev/get-started/install/windows

2. **安装 Visual Studio**：
   - Visual Studio 2022（包含 C++ 桌面开发工具）

### 构建步骤：

1. **启用 Windows 桌面支持**：
   ```cmd
   flutter config --enable-windows-desktop
   ```

2. **获取依赖**：
   ```cmd
   flutter pub get
   ```

3. **构建应用**：
   ```cmd
   flutter build windows --release
   ```

4. **找到构建文件**：
   - 路径：`build\windows\x64\runner\Release\`
   - 主要文件：你的应用.exe 和相关 DLL

## 方法四：使用现有的 Web 版本

我们已经构建了 Web 版本，可以作为临时解决方案：

### 部署 Web 版本：

1. **本地运行**：
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```

2. **访问应用**：
   - 打开浏览器访问：http://localhost:8080
   - 可以在任何操作系统使用

## 分发选项

### Windows 应用分发：

1. **简单分发**：
   - 将 `build\windows\x64\runner\Release\` 目录打包
   - 用户解压后可直接运行

2. **安装包分发**：
   - 使用 MSIX 打包（需要在 Windows 上）
   - 可上传到 Microsoft Store

3. **Web 分发**：
   - 部署 Web 版本到服务器
   - 用户通过浏览器访问

## 故障排除

### 常见问题：

1. **缺少 Visual C++ 运行库**：
   - 下载并安装 Microsoft Visual C++ Redistributable

2. **应用无法启动**：
   - 确保所有 DLL 文件在同一目录
   - 检查依赖项是否完整

3. **Docker 构建失败**：
   - 确保 Docker Desktop 正在运行
   - 检查网络连接（需要下载 Windows 容器）

## 推荐方案

对于你的情况，推荐按以下优先级选择：

1. **GitHub Actions**（最简单）- 自动化构建，无需本地环境
2. **Web 版本**（快速）- 立即可用，跨平台兼容
3. **Docker 构建**（本地）- 需要较好的网络和足够的存储空间
4. **Windows 机器构建**（最直接）- 如果有 Windows 环境可用

选择最适合你当前情况的方案即可！ 