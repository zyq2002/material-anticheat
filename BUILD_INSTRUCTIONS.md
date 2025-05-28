# 物资验收反作弊工具 - 构建指导

## 已完成的构建

### ✅ macOS 版本
- **位置**: `~/Desktop/物资反作弊工具.app`
- **大小**: 54.7MB
- **状态**: ✅ 已完成并复制到桌面
- **说明**: 可以直接双击运行的macOS应用程序

## 构建其他平台版本

### Windows 版本 (.exe)

由于在macOS上无法直接构建Windows版本，有以下几种选择：

#### 方案一：在Windows机器上构建
```bash
# 在Windows机器上执行
flutter build windows --release
```
构建后的文件位置：`build\windows\x64\runner\Release\`

#### 方案二：使用虚拟机
1. 在macOS上安装Windows虚拟机（如Parallels Desktop、VMware Fusion）
2. 在虚拟机中安装Flutter开发环境
3. 将项目代码复制到虚拟机中构建

#### 方案三：使用Docker
```bash
# 使用Windows容器构建
docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:stable flutter build windows --release
```

#### 方案四：使用GitHub Actions（推荐）
创建GitHub仓库并使用CI/CD自动构建多平台版本。

### Linux 版本

```bash
# 在Linux机器上或使用Docker
flutter build linux --release
```

## 应用功能说明

### 主要功能
1. **单日下载**: 下载指定日期的验收记录图片
2. **批量下载**: 批量下载多天的验收记录图片
3. **图片库**: 统一查看和管理已下载的图片
4. **速度控制**: 可调节下载速度避免服务器压力

### 使用方法
1. 启动应用
2. 输入认证Token和Cookie
3. 选择下载方式：
   - 单日下载：在主界面选择日期并启动
   - 批量下载：点击菜单选择"批量下载"
   - 查看图片：点击菜单选择"图片库"

### 文件保存位置
- 默认保存在应用目录下的`pic/images/`文件夹
- 按日期组织：`pic/images/2025-05-26/`
- 按验收记录分组：每个验收记录创建独立文件夹

## 技术细节

### 开发环境
- Flutter 3.x
- Dart 3.x
- 支持平台：macOS, Windows, Linux

### 主要依赖
- `riverpod`: 状态管理
- `flutter_hooks`: React-style hooks
- `dio`: 网络请求
- `shared_preferences`: 本地存储
- `path_provider`: 路径管理

### 架构特点
- 使用Riverpod进行状态管理
- 支持图片下载速度控制
- 文件名安全处理
- 错误处理和重试机制

## 故障排除

### 常见问题
1. **构建失败**: 确保Flutter版本兼容
2. **权限问题**: 确保有文件写入权限
3. **网络问题**: 检查网络连接和认证信息

### 调试模式
```bash
flutter run -d macos    # macOS调试
flutter run -d windows  # Windows调试（仅在Windows上）
flutter run -d linux    # Linux调试（仅在Linux上）
```

## 版本信息
- 版本: 1.0.0
- 构建日期: 2025-05-26
- 支持的最新Flutter版本: 3.x 