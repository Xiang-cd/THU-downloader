import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/file_tree_node.dart';
import 'cloud_api_service.dart';
import 'logger.dart';

class DownloadService {
  /// 下载选中的文件和文件夹
  static Future<void> downloadSelected(
    List<FileTreeNode> selectedNodes,
    String shareKey,
    String savePath,
    {Function(String)? onProgress}
  ) async {
    try {
      CloudDownloadLogger.download('开始下载 ${selectedNodes.length} 个文件到: $savePath');
      
      for (var node in selectedNodes) {
        await _downloadFile(node, shareKey, savePath, onProgress: onProgress);
      }
      
      CloudDownloadLogger.download('所有文件下载完成');
      onProgress?.call('所有文件下载完成');
    } catch (e) {
      CloudDownloadLogger.error('下载过程中发生错误: $e');
      rethrow;
    }
  }

  /// 下载单个文件，根据文件路径创建对应的目录结构
  static Future<void> _downloadFile(
    FileTreeNode fileNode,
    String shareKey,
    String savePath,
    {Function(String)? onProgress}
  ) async {
    try {
      // 从文件路径中提取目录结构和文件名
      final relativePath = fileNode.path.startsWith('/') 
          ? fileNode.path.substring(1) 
          : fileNode.path;
      final fullFilePath = path.join(savePath, relativePath);
      
      onProgress?.call('正在下载: ${fileNode.name}');
      CloudDownloadLogger.download('开始下载文件: ${fileNode.path} 到 $fullFilePath');
      
      final downloadUrl = CloudApiService.getDownloadUrl(shareKey, fileNode.path);
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        throw Exception('下载文件失败: ${fileNode.name}, 状态码: ${response.statusCode}');
      }

      // 确保目录存在（根据文件的完整路径创建目录结构）
      final file = File(fullFilePath);
      await file.parent.create(recursive: true);
      
      // 写入文件
      await file.writeAsBytes(response.bodyBytes);
      
      CloudDownloadLogger.download('文件下载完成: ${fileNode.name} (${fileNode.formattedSize})');
      onProgress?.call('下载完成: ${fileNode.name}');
    } catch (e) {
      CloudDownloadLogger.error('下载文件失败: ${fileNode.name}, 错误: $e');
      rethrow;
    }
  }

  /// 计算选中项目的总大小
  static int calculateTotalSize(List<FileTreeNode> selectedNodes) {
    int totalSize = 0;
    
    for (var node in selectedNodes) {
      totalSize += node.size;
    }
    
    return totalSize;
  }

  /// 格式化文件大小
  static String formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}