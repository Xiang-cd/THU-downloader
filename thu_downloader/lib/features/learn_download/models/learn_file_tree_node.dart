class LearnFileTreeNode {
  final String id;
  final String name;
  final String path;
  final NodeType type;
  final int size;
  List<LearnFileTreeNode> children;
  bool isExpanded;
  bool isSelected;
  bool isPartiallySelected;
  
  // 额外信息
  final String? courseId;
  final String? categoryId;
  final String? fileId;
  final String? fileType;
  final int? uploadTime;

  LearnFileTreeNode({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.size = 0,
    List<LearnFileTreeNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
    this.isPartiallySelected = false,
    this.courseId,
    this.categoryId,
    this.fileId,
    this.fileType,
    this.uploadTime,
  }) : children = children ?? [];

  // 从API响应创建学期节点
  factory LearnFileTreeNode.fromSemester(String semesterId) {
    return LearnFileTreeNode(
      id: semesterId,
      name: _formatSemesterName(semesterId),
      path: semesterId,
      type: NodeType.semester,
    );
  }

  // 从API响应创建课程节点
  factory LearnFileTreeNode.fromCourse(Map<String, dynamic> courseData) {
    return LearnFileTreeNode(
      id: courseData['wlkcid'] ?? '',
      name: courseData['kcm'] ?? courseData['ywkcm'] ?? '',
      path: '${courseData['wlkcid']}',
      type: NodeType.course,
      courseId: courseData['wlkcid'],
    );
  }

  // 从API响应创建分类节点
  factory LearnFileTreeNode.fromCategory(Map<String, dynamic> categoryData) {
    return LearnFileTreeNode(
      id: categoryData['kjflid'] ?? '',
      name: categoryData['bt'] ?? '',
      path: '${categoryData['kjflid']}',
      type: NodeType.category,
      categoryId: categoryData['kjflid'],
    );
  }

  // 从API响应创建文档节点
  factory LearnFileTreeNode.fromDocument(Map<String, dynamic> documentData) {
    // 处理上传时间，可能是字符串时间戳或null
    int? uploadTime;
    final scsj = documentData['scsj'];
    if (scsj != null) {
      if (scsj is int) {
        uploadTime = scsj;
      } else if (scsj is String) {
        uploadTime = int.tryParse(scsj);
      }
    }
    
    return LearnFileTreeNode(
      id: documentData['wjid'] ?? '',
      name: documentData['bt'] ?? '',
      path: '${documentData['wjid']}',
      type: NodeType.document,
      size: _parseInt(documentData['wjdx']) ?? 0,
      fileId: documentData['wjid'],
      fileType: documentData['wjlx'],
      uploadTime: uploadTime,
    );
  }

  // 格式化学期名称
  static String _formatSemesterName(String semesterId) {
    // 将 "2023-2024-1" 格式化为 "2023-2024学年 第1学期"
    final parts = semesterId.split('-');
    if (parts.length >= 3) {
      final year = parts[0];
      final semester = parts[2];
      final semesterName = semester == '1' ? '第1学期' : '第2学期';
      return '$year-${int.parse(year) + 1}学年 $semesterName';
    }
    return semesterId;
  }

  // 解析整数的辅助方法
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // 复制节点（用于状态更新）
  LearnFileTreeNode copyWith({
    String? id,
    String? name,
    String? path,
    NodeType? type,
    int? size,
    List<LearnFileTreeNode>? children,
    bool? isExpanded,
    bool? isSelected,
    bool? isPartiallySelected,
    String? courseId,
    String? categoryId,
    String? fileId,
    String? fileType,
    int? uploadTime,
  }) {
    return LearnFileTreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      children: children ?? List.from(this.children),
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      isPartiallySelected: isPartiallySelected ?? this.isPartiallySelected,
      courseId: courseId ?? this.courseId,
      categoryId: categoryId ?? this.categoryId,
      fileId: fileId ?? this.fileId,
      fileType: fileType ?? this.fileType,
      uploadTime: uploadTime ?? this.uploadTime,
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
    if (type == NodeType.document) {
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
    if (type == NodeType.document) {
      return 1;
    }
    
    int count = 0;
    for (var child in children) {
      count += child.fileCount;
    }
    return count;
  }

  // 获取节点图标
  String get iconName {
    switch (type) {
      case NodeType.semester:
        return '📅';
      case NodeType.course:
        return '📚';
      case NodeType.category:
        return '📁';
      case NodeType.document:
        return _getFileIcon();
    }
  }

  // 根据文件类型获取图标
  String _getFileIcon() {
    if (fileType == null) return '📄';
    
    switch (fileType!.toLowerCase()) {
      case 'pdf':
        return '📕';
      case 'doc':
      case 'docx':
        return '📘';
      case 'ppt':
      case 'pptx':
        return '📙';
      case 'xls':
      case 'xlsx':
        return '📗';
      case 'txt':
        return '📄';
      case 'zip':
      case 'rar':
        return '📦';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      default:
        return '📄';
    }
  }

  // 格式化上传时间
  String get formattedUploadTime {
    if (uploadTime == null) return '';
    
    final date = DateTime.fromMillisecondsSinceEpoch(uploadTime!);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearnFileTreeNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NodeType {
  semester,  // 学期
  course,    // 课程
  category,  // 分类
  document,  // 文档
} 