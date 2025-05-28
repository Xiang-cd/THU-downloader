import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_tree_node.dart';
import 'logger.dart';

class CloudApiService {
  static const String _direntUrlTemplate =
      'https://cloud.tsinghua.edu.cn/api/v2.1/share-links/{shareId}/dirents/?path={path}';
  static const String _downloadUrlTemplate =
      'https://cloud.tsinghua.edu.cn/d/{shareId}/files/?p={filePath}&dl=1';
  static const String _rdownloadUrlTemplate =
      'https://cloud.tsinghua.edu.cn/d/{shareId}/files/?p={filePath}';

  /// 从分享链接中提取shareKey
  static String extractShareKey(String shareLink) {
    final RegExp regExp = RegExp(r'https://cloud\.tsinghua\.edu\.cn/d/(\w+)');
    final Match? match = regExp.firstMatch(shareLink);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    return '';
  }

  /// 验证分享链接并获取基本信息
  static Future<ShareLinkInfo> validateShareLink(String shareLink) async {
    final shareKey = extractShareKey(shareLink);
    if (shareKey.isEmpty) {
      throw Exception('无效的分享链接格式');
    }

    try {
      CloudDownloadLogger.network('正在验证分享链接: $shareLink');
      final response = await http.get(Uri.parse(shareLink));
      
      if (response.statusCode == 404) {
        throw Exception('内容不存在，请检查链接是否正确');
      } else if (response.statusCode == 500) {
        throw Exception('服务暂时不可用，请稍后再试');
      } else if (response.statusCode != 200) {
        throw Exception('网络请求失败，状态码: ${response.statusCode}');
      }

      // 检查是否可以下载
      final canDownload = RegExp(r'canDownload: (.+?),')
          .firstMatch(response.body)?.group(1) == 'true';

      CloudDownloadLogger.network('链接验证成功，shareKey: $shareKey, canDownload: $canDownload');
      
      return ShareLinkInfo(
        shareKey: shareKey,
        canDownload: canDownload,
        originalLink: shareLink,
      );
    } catch (e) {
      CloudDownloadLogger.error('验证分享链接失败: $e');
      rethrow;
    }
  }

  /// 递归获取完整的文件树
  static Future<List<FileTreeNode>> getFileTree(String shareKey, {String path = '/'}) async {
    try {
      CloudDownloadLogger.network('正在获取文件树，路径: $path');
      
      final direntUrl = _direntUrlTemplate
          .replaceAll('{shareId}', shareKey)
          .replaceAll('{path}', Uri.encodeComponent(path));
      
      final response = await http.get(Uri.parse(direntUrl));
      
      if (response.statusCode != 200) {
        throw Exception('获取文件列表失败，状态码: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      final List<dynamic> direntList = responseData['dirent_list'] ?? [];
      
      CloudDownloadLogger.network('获取到 ${direntList.length} 个项目，路径: $path');

      List<FileTreeNode> nodes = [];
      
      for (var item in direntList) {
        final node = FileTreeNode.fromJson(item);
        
        if (node.isDirectory) {
          // 递归获取子文件夹的内容
          try {
            final children = await getFileTree(shareKey, path: node.path);
            nodes.add(node.copyWith(children: children));
            CloudDownloadLogger.network('成功获取文件夹内容: ${node.path}, 子项目数: ${children.length}');
          } catch (e) {
            CloudDownloadLogger.error('获取文件夹内容失败: ${node.path}, 错误: $e');
            // 即使子文件夹获取失败，也添加空的文件夹节点
            nodes.add(node);
          }
        } else {
          nodes.add(node);
        }
      }

      return nodes;
    } catch (e) {
      CloudDownloadLogger.error('获取文件树失败，路径: $path, 错误: $e');
      rethrow;
    }
  }

  /// 获取文件下载URL
  static String getDownloadUrl(String shareKey, String filePath) {
    return _downloadUrlTemplate
        .replaceAll('{shareId}', shareKey)
        .replaceAll('{filePath}', Uri.encodeComponent(filePath));
  }

  /// 获取文件预览URL
  static String getPreviewUrl(String shareKey, String filePath) {
    return _rdownloadUrlTemplate
        .replaceAll('{shareId}', shareKey)
        .replaceAll('{filePath}', Uri.encodeComponent(filePath));
  }

  /// 下载单个文件
  static Future<void> downloadFile(String shareKey, String filePath, String savePath) async {
    try {
      CloudDownloadLogger.download('开始下载文件: $filePath');
      
      final downloadUrl = getDownloadUrl(shareKey, filePath);
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        throw Exception('下载失败，状态码: ${response.statusCode}');
      }

      // 这里应该将文件保存到指定路径
      // 具体的文件保存逻辑需要根据平台实现
      CloudDownloadLogger.download('文件下载完成: $filePath');
    } catch (e) {
      CloudDownloadLogger.error('下载文件失败: $filePath, 错误: $e');
      rethrow;
    }
  }
}

/// 分享链接信息
class ShareLinkInfo {
  final String shareKey;
  final bool canDownload;
  final String originalLink;

  ShareLinkInfo({
    required this.shareKey,
    required this.canDownload,
    required this.originalLink,
  });
} 