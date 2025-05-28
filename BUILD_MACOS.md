# macOS 应用构建指南

## 🎉 构建成功！

您的 Flutter 物资防作弊应用已成功构建为 macOS 应用！

### 📦 构建产物

- **应用文件夹**: `物资anticheat-macOS/`
- **压缩包**: `物资anticheat-macOS.zip` (54MB)
- **应用文件**: `material_anticheat.app`

### 🚀 安装说明

#### 方式一：直接安装（推荐）
1. 解压 `物资anticheat-macOS.zip`
2. 将 `material_anticheat.app` 拖拽到 `Applications`（应用程序）文件夹
3. 双击应用图标运行

#### 方式二：临时运行
1. 解压后直接双击 `material_anticheat.app` 运行
2. 无需安装到应用程序文件夹

### ⚠️ 安全提示

首次运行时，macOS 可能会显示安全警告，因为应用未经过 Apple 签名。

#### 解决方法：

**方法1：右键打开**
1. 右键点击应用
2. 选择"打开"
3. 在弹出对话框中再次点击"打开"

**方法2：系统设置**
1. 打开"系统偏好设置" > "安全性与隐私" > "通用"
2. 点击"仍要打开"按钮
3. 或选择"任何来源"（不推荐）

**方法3：终端命令**（如果遇到权限问题）
```bash
# 去除隔离属性
xattr -cr /Applications/material_anticheat.app

# 或者（如果应用在其他位置）
xattr -cr /path/to/material_anticheat.app
```

### 💻 系统要求

- **操作系统**: macOS 10.15 (Catalina) 或更高版本
- **处理器**: 支持 Apple Silicon (M1/M2/M3) 和 Intel 处理器
- **内存**: 建议 4GB 以上
- **存储**: 应用大小约 55MB

### 🔧 技术信息

- **Flutter 版本**: 3.32.0
- **构建模式**: Release (优化版本)
- **架构**: ARM64 (Apple Silicon) 优先
- **兼容性**: 支持 Intel Mac 通过 Rosetta 2 运行

### 📱 应用功能

✅ 物资检查记录管理  
✅ 图片对比分析  
✅ 数据同步  
✅ 报告生成  
✅ 本地数据存储  

### 🛠 开发者信息

如需重新构建或修改应用：

```bash
# 启用 macOS 桌面支持
flutter config --enable-macos-desktop

# 获取依赖
flutter pub get

# 构建 macOS 应用
flutter build macos --release

# 创建分发包
./create-macos-package.sh
```

### 📋 分发清单

构建完成后包含以下文件：

```
物资anticheat-macOS/
├── material_anticheat.app          # 主应用文件
└── 安装说明.txt                    # 安装说明

物资anticheat-macOS.zip             # 压缩分发包
```

### 🔍 故障排除

#### 问题1：应用无法启动
**症状**: 双击后没有反应或立即退出  
**解决**: 
1. 检查 macOS 版本是否满足要求
2. 尝试从终端启动查看错误信息：
   ```bash
   /Applications/material_anticheat.app/Contents/MacOS/material_anticheat
   ```

#### 问题2：网络连接错误
**症状**: 应用显示网络错误  
**解决**: 
1. 检查网络连接
2. 确认防火墙设置允许应用联网
3. 在"系统偏好设置" > "安全性与隐私" > "隐私" > "网络"中允许应用

#### 问题3：数据同步问题
**症状**: 数据无法同步或保存  
**解决**: 
1. 检查应用的文件访问权限
2. 确保有足够的磁盘空间
3. 重启应用重试

### 📞 技术支持

如果遇到其他问题：
1. 检查控制台应用中的错误日志
2. 联系开发团队并提供详细的错误信息
3. 包含系统版本、硬件信息等

### 🎯 下一步

应用已就绪！您可以：
- 分发给最终用户使用
- 部署到多台 Mac 设备
- 考虑通过 Apple Developer Program 进行代码签名（用于企业分发）

---

**构建时间**: $(date)  
**构建环境**: macOS 15.5 (Apple Silicon)  
**Flutter 版本**: 3.32.0 