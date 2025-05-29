# 物资反作弊工具 - 发布包说明

## 📦 包含文件

### 1. 源代码归档
- **物资anticheat-source-complete.tar.gz** (184MB)
  - 完整的Flutter项目源代码
  - 包含所有必要的配置文件
  - 包含Python脚本和依赖说明
  - 用于在Windows设备上构建exe文件

### 2. macOS应用
- **物资anticheat-macOS.dmg** (24MB)
  - macOS安装包，拖拽即可安装
  - 适用于macOS 10.14+
  - 支持Intel和Apple Silicon芯片

- **物资anticheat-macOS.app** 
  - 独立的macOS应用程序
  - 可直接运行，无需安装

## 🛠️ Windows EXE 构建说明

### 环境要求
1. **Flutter SDK** - Windows版本
2. **Python 3.9+** 及相关依赖包
3. **Visual Studio 2019+** 或 **Build Tools**

### 构建步骤
1. 解压 `物资anticheat-source-complete.tar.gz`
2. 进入项目目录
3. 运行以下命令：
```cmd
flutter clean
flutter pub get
flutter build windows --release
```

### 详细说明
请参考项目中的 `BUILD_WINDOWS_EXE.md` 文件获取完整的构建说明。

## 🚀 功能特性

### 物资验收模块
- ✅ 验收记录自动爬取
- ✅ 物资图片下载整理
- ✅ 重复图片检测
- ✅ 可疑图片识别
- ✅ 批量下载功能

### 过磅记录模块
- ✅ 过磅记录自动爬取
- ✅ 车辆多角度照片下载
- ✅ 按记录ID智能分类
- ✅ 批量日期范围下载
- ✅ 详细日志记录

### 图片分析功能
- ✅ 基于SIFT特征的图片相似度检测
- ✅ 可疑图片自动标记
- ✅ 批量图片管理
- ✅ 7列网格显示布局
- ✅ 图片预览和删除功能

## 📋 系统要求

### macOS版本
- macOS 10.14 或更高版本
- 最少 4GB 内存
- 500MB 可用磁盘空间

### Windows版本
- Windows 10 或更高版本
- Flutter运行时环境
- Python 3.9+ 及相关依赖包
- 最少 4GB 内存
- 1GB 可用磁盘空间

## 📝 使用说明

### 首次启动
1. 配置Authorization Token和Cookie
2. 设置图片保存路径
3. 选择要爬取的日期范围

### 物资验收
1. 进入"物资验收"模块
2. 点击"开始爬虫"按钮
3. 查看"图片库"中的下载结果
4. 使用"可疑图片检测"功能分析

### 过磅记录
1. 进入"过磅记录"模块
2. 设置日期范围
3. 点击"批量下载"
4. 在"过磅图片库"中查看结果

## 🔧 故障排除

### 常见问题
1. **Python环境问题**：确保Python在系统PATH中
2. **网络连接问题**：检查防火墙和代理设置
3. **权限问题**：以管理员身份运行应用
4. **依赖包缺失**：参考requirements.txt安装依赖

### 日志查看
- 应用内置日志系统
- 详细的操作记录和错误信息
- 支持日志导出功能

## 📞 技术支持

如有技术问题，请查看项目中的详细文档或联系开发团队。

---
**版本**: v1.0.0  
**构建日期**: 2025-01-28  
**支持平台**: macOS, Windows 