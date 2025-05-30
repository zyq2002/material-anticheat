# 可疑图片检测功能说明

## 功能概述

本功能使用先进的SIFT（尺度不变特征变换）算法自动检测同一天内不同验收记录之间相似度过高的图片，帮助识别可能的作弊行为。

## 主要特性

### 🔍 智能检测算法
- **SIFT特征匹配**：使用计算机视觉算法分析图像特征点
- **直方图分析**：补充颜色分布相似度分析
- **综合评分**：结合两种算法给出0-100的相似度分数

### 🎯 精准分类对比
- **按图片类型分组**：验收照片1-7、送货单等分别对比
- **同类型比较**：只对比相同位置的图片，提高检测准确性
- **跨记录检测**：在同一天内不同验收记录之间进行对比

### 📊 可视化展示
- **高亮显示**：可疑图片在图片库中用红色边框和警告图标标识
- **相似度指示器**：用颜色区分不同相似度等级
- **详细对比**：并排显示可疑图片对，便于人工核验

## 使用方法

### 1. 启动检测

#### 方式一：从主菜单进入
1. 点击主界面右上角的菜单按钮（⋮）
2. 选择"可疑图片检测"
3. 系统自动开始检测今日图片

#### 方式二：从图片库进入
1. 进入"图片库"页面
2. 点击右上角的盾牌图标（🛡️）
3. 进入可疑图片检测页面

### 2. 设置检测参数

#### 相似度阈值设置
- **默认阈值**：30%
- **建议范围**：20-50%
- **调整方法**：拖动滑块或点击设置按钮
- **阈值说明**：
  - 阈值越低，检测越严格，可能产生误报
  - 阈值越高，检测越宽松，可能漏检
  - 建议根据实际情况调整

#### 筛选和排序
- **类型筛选**：可按图片类型筛选结果
- **排序方式**：支持按相似度、检测时间、图片类型排序

### 3. 查看检测结果

#### 状态指示
- **绿色✅**：未发现可疑图片
- **橙色⚠️**：发现可疑图片，显示数量

#### 结果详情
每个检测结果包含：
- **相似度分数**：用颜色标识严重程度
  - 🔴 红色：80%以上（高度可疑）
  - 🟠 橙色：60-80%（中度可疑）
  - 🟡 黄色：40-60%（轻度可疑）
  - 🔵 蓝色：40%以下（需关注）
- **记录信息**：显示涉及的两个验收记录ID
- **图片预览**：并排显示可疑图片对
- **操作按钮**：详细对比、打开目录

### 4. 图片库中的高亮显示

在图片库页面中，可疑图片会：
- **红色边框**：3像素宽的红色边框
- **红色阴影**：增强视觉效果
- **警告图标**：右上角显示红色警告标识

## 技术原理

### SIFT算法
- **特征点检测**：识别图像中的关键特征点
- **描述符生成**：为每个特征点生成唯一描述符
- **特征匹配**：使用FLANN匹配器进行快速匹配
- **相似度计算**：基于匹配特征点数量计算相似度

### 直方图分析
- **颜色分布**：分析图像的颜色直方图
- **相关性计算**：使用OpenCV的直方图比较功能
- **补充验证**：作为SIFT算法的补充验证

### 综合评分
- **权重分配**：SIFT 70% + 直方图 30%
- **结果融合**：综合两种算法的优势
- **准确性提升**：减少单一算法的误判

## 注意事项

### 环境要求
- **Python环境**：需要安装Python虚拟环境
- **依赖包**：opencv-python、numpy等
- **系统支持**：macOS、Windows、Linux

### 性能考虑
- **检测时间**：取决于图片数量和大小
- **内存使用**：大量图片可能占用较多内存
- **CPU负载**：SIFT算法计算密集

### 使用建议
1. **定期检测**：建议每日检测当天图片
2. **阈值调整**：根据实际情况调整检测阈值
3. **人工核验**：检测结果需要人工最终确认
4. **备份数据**：重要图片建议备份保存

## 故障排除

### 常见问题

#### 1. Python脚本执行失败
- **检查Python环境**：确保虚拟环境正确安装
- **验证依赖包**：运行 `pip list` 检查依赖
- **路径问题**：确保图片路径正确

#### 2. 检测结果异常
- **图片格式**：确保图片格式支持（jpg、png等）
- **图片质量**：过小或模糊的图片可能影响检测
- **阈值设置**：尝试调整相似度阈值

#### 3. 性能问题
- **图片数量**：大量图片会影响检测速度
- **系统资源**：确保有足够的内存和CPU资源
- **后台运行**：避免同时运行其他资源密集型程序

### 技术支持
如遇到技术问题，请检查：
1. Flutter应用日志
2. Python脚本输出
3. 系统错误信息
4. 网络连接状态

## 更新日志

### v1.0.0 (2024-01-XX)
- ✅ 基础SIFT相似度检测
- ✅ 图片库高亮显示
- ✅ 可疑图片筛选页面
- ✅ 阈值设置功能
- ✅ 多种排序和筛选选项

### 计划功能
- 🔄 批量检测多日图片
- 🔄 检测结果导出
- 🔄 更多图像算法支持
- 🔄 检测报告生成 