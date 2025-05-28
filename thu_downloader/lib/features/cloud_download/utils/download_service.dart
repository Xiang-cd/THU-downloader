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
      CloudDownloadLogger.download('开始下载 ${selectedNodes.length} 个项目到: $savePath');
      
      for (var node in selectedNodes) {
        if (node.isDirectory) {
          await _downloadDirectory(node, shareKey, savePath, onProgress: onProgress);
        } else {
          await _downloadFile(node, shareKey, savePath, onProgress: onProgress);
        }
      }
      
      CloudDownloadLogger.download('所有文件下载完成');
      onProgress?.call('所有文件下载完成');
    } catch (e) {
      CloudDownloadLogger.error('下载过程中发生错误: $e');
      rethrow;
    }
  }

  /// 下载单个文件
  static Future<void> _downloadFile(
    FileTreeNode fileNode,
    String shareKey,
    String savePath,
    {Function(String)? onProgress}
  ) async {
    try {
      final fileName = fileNode.name;
      final filePath = path.join(savePath, fileName);
      
      onProgress?.call('正在下载: $fileName');
      CloudDownloadLogger.download('开始下载文件: ${fileNode.path}');
      
      final downloadUrl = CloudApiService.getDownloadUrl(shareKey, fileNode.path);
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        throw Exception('下载文件失败: $fileName, 状态码: ${response.statusCode}');
      }

      // 确保目录存在
      final file = File(filePath);
      await file.parent.create(recursive: true);
      
      // 写入文件
      await file.writeAsBytes(response.bodyBytes);
      
      CloudDownloadLogger.download('文件下载完成: $fileName (${fileNode.formattedSize})');
      onProgress?.call('下载完成: $fileName');
    } catch (e) {
      CloudDownloadLogger.error('下载文件失败: ${fileNode.name}, 错误: $e');
      rethrow;
    }
  }

  /// 递归下载文件夹
  static Future<void> _downloadDirectory(
    FileTreeNode dirNode,
    String shareKey,
    String savePath,
    {Function(String)? onProgress}
  ) async {
    try {
      final dirPath = path.join(savePath, dirNode.name);
      
      onProgress?.call('正在创建文件夹: ${dirNode.name}');
      CloudDownloadLogger.download('开始下载文件夹: ${dirNode.path}');
      
      // 创建文件夹
      final dir = Directory(dirPath);
      await dir.create(recursive: true);
      
      // 递归下载文件夹内容
      await _downloadDirectoryContents(dirNode, shareKey, dirPath, onProgress: onProgress);
      
      CloudDownloadLogger.download('文件夹下载完成: ${dirNode.name}');
    } catch (e) {
      CloudDownloadLogger.error('下载文件夹失败: ${dirNode.name}, 错误: $e');
      rethrow;
    }
  }

  /// 递归下载文件夹内容
  static Future<void> _downloadDirectoryContents(
    FileTreeNode dirNode,
    String shareKey,
    String currentPath,
    {Function(String)? onProgress}
  ) async {
    for (var child in dirNode.children) {
      if (child.isDirectory) {
        // 递归下载子文件夹
        final subDirPath = path.join(currentPath, child.name);
        final subDir = Directory(subDirPath);
        await subDir.create(recursive: true);
        
        await _downloadDirectoryContents(child, shareKey, subDirPath, onProgress: onProgress);
      } else {
        // 下载文件
        final filePath = path.join(currentPath, child.name);
        
        onProgress?.call('正在下载: ${child.name}');
        CloudDownloadLogger.download('下载文件: ${child.path}');
        
        final downloadUrl = CloudApiService.getDownloadUrl(shareKey, child.path);
        final response = await http.get(Uri.parse(downloadUrl));
        
        if (response.statusCode != 200) {
          CloudDownloadLogger.error('下载文件失败: ${child.name}, 状态码: ${response.statusCode}');
          continue; // 继续下载其他文件
        }

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        CloudDownloadLogger.download('文件下载完成: ${child.name} (${child.formattedSize})');
        onProgress?.call('下载完成: ${child.name}');
      }
    }
  }

  /// 计算选中项目的总大小
  static int calculateTotalSize(List<FileTreeNode> selectedNodes) {
    int totalSize = 0;
    
    for (var node in selectedNodes) {
      if (node.isDirectory) {
        totalSize += _calculateDirectorySize(node);
      } else {
        totalSize += node.size;
      }
    }
    
    return totalSize;
  }

  /// 递归计算文件夹大小
  static int _calculateDirectorySize(FileTreeNode dirNode) {
    int size = 0;
    
    for (var child in dirNode.children) {
      if (child.isDirectory) {
        size += _calculateDirectorySize(child);
      } else {
        size += child.size;
      }
    }
    
    return size;
  }

  /// 格式化文件大小
  static String formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
} 