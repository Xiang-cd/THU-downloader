import '../models/learn_file_tree_node.dart';
import 'learn_api_service.dart';

class LearnDownloadService {
  final LearnApiService _apiService;
  
  LearnDownloadService(this._apiService);

  // 构建课件文件树
  Future<List<LearnFileTreeNode>> buildCoursewareTree(String csrfToken) async {
    try {
      // 1. 获取学期列表
      final semesters = await _apiService.getSemesters(csrfToken);
      print('Semesters: $semesters');
      if (semesters.isEmpty) {
        return [];
      }

      List<LearnFileTreeNode> semesterNodes = [];

      // 2. 为每个学期获取课程
      for (String semesterId in semesters) {
        final semesterNode = LearnFileTreeNode.fromSemester(semesterId);
        final courses = await _apiService.getCourses(csrfToken, semesterId);
        
        List<LearnFileTreeNode> courseNodes = [];

        // 3. 为每个课程获取文档分类和文档
        for (var courseData in courses) {
          final courseNode = LearnFileTreeNode.fromCourse(courseData);
          final courseId = courseData['wlkcid'];
          
          // 获取文档分类
          final categories = await _apiService.getDocumentCategories(csrfToken, courseId);
          List<LearnFileTreeNode> categoryNodes = [];

          // 4. 为每个分类获取文档
          for (var categoryData in categories) {
            final categoryNode = LearnFileTreeNode.fromCategory(categoryData);
            
            // 获取该分类下的所有文档
            final documents = await _apiService.getDocuments(csrfToken, courseId);
            
            // 过滤出属于当前分类的文档
            final categoryDocuments = documents.where((doc) => 
              doc['kjflid'].toString() == categoryData['kjflid'].toString()
            ).toList();

            List<LearnFileTreeNode> documentNodes = [];
            for (var documentData in categoryDocuments) {
              final documentNode = LearnFileTreeNode.fromDocument(documentData);
              documentNodes.add(documentNode);
            }

            // 将文档添加到分类节点
            categoryNode.children.addAll(documentNodes);
            categoryNodes.add(categoryNode);
          }

          // 将分类添加到课程节点
          courseNode.children.addAll(categoryNodes);
          courseNodes.add(courseNode);
        }

        // 将课程添加到学期节点
        semesterNode.children.addAll(courseNodes);
        semesterNodes.add(semesterNode);
      }

      return semesterNodes;
    } catch (e) {
      print('Error building courseware tree: $e');
      return [];
    }
  }

  // 获取选中的文档列表
  List<LearnFileTreeNode> getSelectedDocuments(List<LearnFileTreeNode> tree) {
    List<LearnFileTreeNode> selected = [];
    _collectSelectedDocuments(tree, selected);
    return selected;
  }

  void _collectSelectedDocuments(List<LearnFileTreeNode> nodes, List<LearnFileTreeNode> selected) {
    for (var node in nodes) {
      if (node.isSelected && node.type == NodeType.document) {
        selected.add(node);
      }
      _collectSelectedDocuments(node.children, selected);
    }
  }

  // 获取选中文档的统计信息
  Map<String, dynamic> getSelectionStats(List<LearnFileTreeNode> tree) {
    final selectedDocuments = getSelectedDocuments(tree);
    int totalSize = 0;
    int fileCount = selectedDocuments.length;
    
    for (var document in selectedDocuments) {
      totalSize += document.size;
    }
    
    return {
      'fileCount': fileCount,
      'totalSize': totalSize,
      'formattedTotalSize': _formatSize(totalSize),
    };
  }

  String _formatSize(int size) {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 展开指定节点（用于懒加载）
  Future<void> expandNode(LearnFileTreeNode node, String csrfToken) async {
    if (node.type == NodeType.semester && node.children.isEmpty) {
      // 展开学期节点，加载课程
      final courses = await _apiService.getCourses(csrfToken, node.id);
      List<LearnFileTreeNode> courseNodes = [];
      
      for (var courseData in courses) {
        final courseNode = LearnFileTreeNode.fromCourse(courseData);
        courseNodes.add(courseNode);
      }
      
      node.children.addAll(courseNodes);
    } else if (node.type == NodeType.course && node.children.isEmpty) {
      // 展开课程节点，加载分类
      final categories = await _apiService.getDocumentCategories(csrfToken, node.courseId!);
      List<LearnFileTreeNode> categoryNodes = [];
      
      for (var categoryData in categories) {
        final categoryNode = LearnFileTreeNode.fromCategory(categoryData);
        categoryNodes.add(categoryNode);
      }
      
      node.children.addAll(categoryNodes);
    } else if (node.type == NodeType.category && node.children.isEmpty) {
      // 展开分类节点，加载文档
      final documents = await _apiService.getDocuments(csrfToken, node.courseId!);
      
      // 过滤出属于当前分类的文档
      final categoryDocuments = documents.where((doc) => 
        doc['kjflid'].toString() == node.categoryId
      ).toList();

      List<LearnFileTreeNode> documentNodes = [];
      for (var documentData in categoryDocuments) {
        final documentNode = LearnFileTreeNode.fromDocument(documentData);
        documentNodes.add(documentNode);
      }
      
      node.children.addAll(documentNodes);
    }
  }

  void dispose() {
    // 不再需要dispose _apiService，因为它由外部管理
  }
} 