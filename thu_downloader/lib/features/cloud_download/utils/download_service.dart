import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/file_tree_node.dart';
import 'cloud_api_service.dart';
import 'logger.dart';

class DownloadService {
  static bool _isCancelled = false;

  /// 取消当前下载
  static void cancelDownload() {
    _isCancelled = true;
  }

  /// 重置取消状态
  static void resetCancellation() {
    _isCancelled = false;
  }

  /// 检查是否已取消
  static bool get isCancelled => _isCancelled;

  /// 下载选中的文件和文件夹
  static Future<void> downloadSelected(
    List<FileTreeNode> selectedNodes,
    String shareKey,
    String savePath,
    {Function(String)? onProgress,
     Function(int downloadedBytes, int totalBytes)? onProgressBytes}
  ) async {
    try {
      resetCancellation(); // 重置取消状态
      final totalBytes = calculateTotalSize(selectedNodes);
      int completedBytes = 0; // 已完成文件的字节数
      int currentFileDownloadedBytes = 0; // 当前文件已下载的字节数
      
      CloudDownloadLogger.download('开始下载 ${selectedNodes.length} 个文件到: $savePath');
      onProgressBytes?.call(0, totalBytes);
      
      for (var node in selectedNodes) {
        // 检查是否已取消
        if (_isCancelled) {
          CloudDownloadLogger.download('下载已取消');
          onProgress?.call('下载已取消');
          return;
        }

        currentFileDownloadedBytes = 0; // 重置当前文件进度
        
        await _downloadFile(
          node, 
          shareKey, 
          savePath, 
          onProgress: onProgress,
          onFileDownloaded: (fileSize) {
            completedBytes += fileSize;
            currentFileDownloadedBytes = 0; // 文件完成后重置
            onProgressBytes?.call(completedBytes, totalBytes);
          },
          onFileProgress: (currentFileBytes, totalFileBytes) {
            currentFileDownloadedBytes = currentFileBytes;
            // 总进度 = 已完成的文件字节数 + 当前文件已下载字节数
            final totalDownloaded = completedBytes + currentFileDownloadedBytes;
            onProgressBytes?.call(totalDownloaded, totalBytes);
          }
        );
      }
      
      if (!_isCancelled) {
        CloudDownloadLogger.download('所有文件下载完成');
        onProgress?.call('所有文件下载完成');
        onProgressBytes?.call(totalBytes, totalBytes);
      }
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
    {Function(String)? onProgress,
     Function(int)? onFileDownloaded,
     Function(int currentFileBytes, int totalFileBytes)? onFileProgress}
  ) async {
    try {
      // 检查是否已取消
      if (_isCancelled) {
        return;
      }

      // 从文件路径中提取目录结构和文件名
      final relativePath = fileNode.path.startsWith('/') 
          ? fileNode.path.substring(1) 
          : fileNode.path;
      final fullFilePath = path.join(savePath, relativePath);
      
      onProgress?.call('正在下载: ${fileNode.name}');
      CloudDownloadLogger.download('开始下载文件: ${fileNode.path} 到 $fullFilePath');
      
      final downloadUrl = CloudApiService.getDownloadUrl(shareKey, fileNode.path);
      
      // 使用流式下载
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await request.send();
      
      if (response.statusCode != 200) {
        throw Exception('下载文件失败: ${fileNode.name}, 状态码: ${response.statusCode}');
      }

      // 确保目录存在（根据文件的完整路径创建目录结构）
      final file = File(fullFilePath);
      await file.parent.create(recursive: true);
      
      // 流式写入文件并更新进度
      final sink = file.openWrite();
      int downloadedBytes = 0;
      final totalBytes = fileNode.size;
      
      await for (final chunk in response.stream) {
        // 检查是否已取消
        if (_isCancelled) {
          await sink.close();
          // 删除未完成的文件
          if (await file.exists()) {
            await file.delete();
          }
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        // 更新当前文件的下载进度
        onFileProgress?.call(downloadedBytes, totalBytes);
        
        // 可以在这里添加更详细的进度信息
        if (totalBytes > 0) {
          final progress = (downloadedBytes / totalBytes * 100).toStringAsFixed(1);
          onProgress?.call('正在下载: ${fileNode.name} ($progress%)');
        }
      }
      
      await sink.close();
      
      // 只有在未取消的情况下才通知文件下载完成
      if (!_isCancelled) {
        onFileDownloaded?.call(fileNode.size);
        CloudDownloadLogger.download('文件下载完成: ${fileNode.name} (${fileNode.formattedSize})');
        onProgress?.call('下载完成: ${fileNode.name}');
      }
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