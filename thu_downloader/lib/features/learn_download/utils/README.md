 # 清华网络学堂课件下载功能

## 功能概述

本模块实现了清华网络学堂课件的批量下载功能，支持：

- 流式下载，带进度条
- 可取消下载
- 按文件树结构组织下载的文件
- 支持多平台（Android、iOS、Desktop）

## 主要组件

### 1. DownloadManager
下载管理器，负责：
- 管理下载任务
- 处理下载进度
- 支持取消下载
- 文件路径构建

### 2. DownloadProgressDialog
下载进度对话框，显示：
- 总体下载进度
- 单个文件下载状态
- 下载统计信息
- 取消下载功能

### 3. LearnFileTreeNode
文件树节点模型，包含：
- 父子关系维护
- 文件路径构建
- 文件类型识别

## 使用方法

### 1. 基本使用

```dart
// 创建下载管理器
final downloadManager = DownloadManager();

// 选择下载目录
String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
  dialogTitle: 'Select download directory',
);

// 开始下载
await downloadManager.downloadFile(
  document,  // LearnFileTreeNode
  selectedDirectory,
  csrfToken,
);
```

### 2. 显示下载进度

```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => DownloadProgressDialog(
    selectedDocuments: selectedDocuments,
    csrfToken: csrfToken,
    baseDirectory: selectedDirectory,
    downloadManager: downloadManager,
  ),
);
```

### 3. 监听下载进度

```dart
// 监听任务状态变化
downloadManager.taskStream.listen((task) {
  print('Task ${task.document.name}: ${task.status}');
});

// 监听下载进度
downloadManager.progressStream.listen((progress) {
  print('Progress: ${(progress.progress * 100).toStringAsFixed(1)}%');
});
```

## 文件结构

下载的文件会按照以下结构组织：

```
下载目录/
├── 2023-2024学年 第1学期/
│   ├── 数据结构/
│   │   ├── 课件/
│   │   │   ├── 第一章 绪论.pdf
│   │   │   └── 第二章 线性表.pdf
│   │   └── 参考资料/
│   │       └── 实验指导书.pdf
│   └── 计算机组成原理/
│       └── 课件/
│           └── 第一章 计算机系统概论.pdf
└── 2023-2024学年 第2学期/
    └── ...
```

## 权限要求

### Android
需要存储权限：
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS
不需要特殊权限，文件保存在应用的Documents目录中。

### Desktop
不需要特殊权限。

## 错误处理

下载过程中可能遇到的错误：

1. **网络错误**：自动重试机制
2. **权限错误**：提示用户授权
3. **文件已存在**：自动覆盖
4. **磁盘空间不足**：提示用户清理空间

## 注意事项

1. 确保在widget销毁时取消流监听器
2. 下载大文件时注意内存使用
3. 网络不稳定时建议实现重试机制
4. 文件路径中的特殊字符会被自动处理

## 依赖包

```yaml
dependencies:
  dio: ^5.4.0
  path: ^1.8.3
  file_picker: ^8.1.2
  permission_handler: ^11.3.1
  path_provider: ^2.1.4
```