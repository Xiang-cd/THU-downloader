class FileTreeNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final List<FileTreeNode> children;
  bool isExpanded;
  bool isSelected;
  bool isPartiallySelected; // 用于表示部分子节点被选中的状态

  FileTreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.children = const [],
    this.isExpanded = false,
    this.isSelected = false,
    this.isPartiallySelected = false,
  });

  // 从API响应创建节点
  factory FileTreeNode.fromJson(Map<String, dynamic> json) {
    return FileTreeNode(
      name: json['file_name'] ?? json['folder_name'] ?? '',
      path: json['file_path'] ?? json['folder_path'] ?? '',
      isDirectory: json['is_dir'] ?? false,
      size: json['size'] ?? 0,
    );
  }

  // 创建demo数据
  static List<FileTreeNode> createDemoData() {
    return [
      FileTreeNode(
        name: '课程资料',
        path: '/课程资料',
        isDirectory: true,
        children: [
          FileTreeNode(
            name: '第一章',
            path: '/课程资料/第一章',
            isDirectory: true,
            children: [
              FileTreeNode(
                name: '1.1 概述.pdf',
                path: '/课程资料/第一章/1.1 概述.pdf',
                isDirectory: false,
                size: 1024000,
              ),
              FileTreeNode(
                name: '1.2 基础知识.pdf',
                path: '/课程资料/第一章/1.2 基础知识.pdf',
                isDirectory: false,
                size: 2048000,
              ),
            ],
          ),
          FileTreeNode(
            name: '第二章',
            path: '/课程资料/第二章',
            isDirectory: true,
            children: [
              FileTreeNode(
                name: '2.1 进阶内容.pdf',
                path: '/课程资料/第二章/2.1 进阶内容.pdf',
                isDirectory: false,
                size: 3072000,
              ),
              FileTreeNode(
                name: '练习题',
                path: '/课程资料/第二章/练习题',
                isDirectory: true,
                children: [
                  FileTreeNode(
                    name: '练习1.docx',
                    path: '/课程资料/第二章/练习题/练习1.docx',
                    isDirectory: false,
                    size: 512000,
                  ),
                  FileTreeNode(
                    name: '练习2.docx',
                    path: '/课程资料/第二章/练习题/练习2.docx',
                    isDirectory: false,
                    size: 768000,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      FileTreeNode(
        name: '作业提交',
        path: '/作业提交',
        isDirectory: true,
        children: [
          FileTreeNode(
            name: '作业1.zip',
            path: '/作业提交/作业1.zip',
            isDirectory: false,
            size: 5120000,
          ),
          FileTreeNode(
            name: '作业2.zip',
            path: '/作业提交/作业2.zip',
            isDirectory: false,
            size: 4096000,
          ),
        ],
      ),
      FileTreeNode(
        name: '说明文档.txt',
        path: '/说明文档.txt',
        isDirectory: false,
        size: 1024,
      ),
    ];
  }

  // 复制节点（用于状态更新）
  FileTreeNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    List<FileTreeNode>? children,
    bool? isExpanded,
    bool? isSelected,
    bool? isPartiallySelected,
  }) {
    return FileTreeNode(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      isPartiallySelected: isPartiallySelected ?? this.isPartiallySelected,
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 计算文件夹的总大小（递归计算所有子文件的大小）
  int get totalSize {
    if (!isDirectory) {
      return size;
    }
    
    int total = 0;
    for (var child in children) {
      total += child.totalSize;
    }
    return total;
  }

  // 格式化文件夹的总大小
  String get formattedTotalSize {
    final total = totalSize;
    if (total < 1024) return '${total}B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)}KB';
    if (total < 1024 * 1024 * 1024) return '${(total / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 获取文件夹中的文件数量
  int get fileCount {
    if (!isDirectory) {
      return 1;
    }
    
    int count = 0;
    for (var child in children) {
      count += child.fileCount;
    }
    return count;
  }
} 