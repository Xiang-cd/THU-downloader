import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_tree_node.dart';
import '../widgets/file_tree_widget.dart';
import '../utils/logger.dart';
import '../utils/cloud_api_service.dart';
import '../utils/download_service.dart';

class CloudDownloadScreen extends StatefulWidget {
  const CloudDownloadScreen({super.key});

  @override
  State<CloudDownloadScreen> createState() => _CloudDownloadScreenState();
}

class _CloudDownloadScreenState extends State<CloudDownloadScreen> {
  final TextEditingController _linkController = TextEditingController();
  List<FileTreeNode> _fileNodes = [];
  List<FileTreeNode> _selectedNodes = [];
  String _statusMessage = '请输入清华云盘分享链接';
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _shareKey;
  bool _canDownload = false;
  
  // 下载进度相关变量
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  double _downloadProgress = 0.0;
  String _currentFileName = '';
  int _currentFileBytes = 0;
  int _currentFileTotalBytes = 0;

  void _onSelectionChanged(List<FileTreeNode> selectedNodes) {
    setState(() {
      _selectedNodes = selectedNodes;
    });
    CloudDownloadLogger.selection('选中的文件数量: ${selectedNodes.length} (不包括文件夹)');
    for (var node in selectedNodes) {
      CloudDownloadLogger.selection('选中文件: ${node.path}');
    }
  }

  // 计算选中文件的总大小
  int _calculateSelectedSize() {
    int totalSize = 0;
    for (var node in _selectedNodes) {
      totalSize += node.size;
    }
    return totalSize;
  }

  // 格式化选中文件的总大小
  String _formatSelectedSize() {
    final totalSize = _calculateSelectedSize();
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Future<void> _parseLink() async {
    if (_linkController.text.isEmpty) {
      setState(() {
        _statusMessage = '请输入分享链接';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在验证链接...';
      _fileNodes = [];
      _selectedNodes = [];
      _shareKey = null;
      _canDownload = false;
    });

    try {
      // 验证分享链接
      final linkInfo = await CloudApiService.validateShareLink(_linkController.text);
      
      setState(() {
        _statusMessage = '链接验证成功，正在获取文件树...';
        _shareKey = linkInfo.shareKey;
        _canDownload = linkInfo.canDownload;
      });

      // 递归获取完整的文件树
      final fileTree = await CloudApiService.getFileTree(linkInfo.shareKey);
      
      setState(() {
        _isLoading = false;
        _fileNodes = fileTree;
        _statusMessage = _canDownload 
          ? '链接解析成功，共找到 ${_countTotalFiles(fileTree)} 个文件，可以下载'
          : '链接解析成功，共找到 ${_countTotalFiles(fileTree)} 个文件，仅预览模式';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '解析失败: ${e.toString()}';
        _fileNodes = [];
        _shareKey = null;
        _canDownload = false;
      });
      CloudDownloadLogger.error('解析链接失败: $e');
    }
  }

  int _countTotalFiles(List<FileTreeNode> nodes) {
    int count = 0;
    for (var node in nodes) {
      if (node.isDirectory) {
        count += _countTotalFiles(node.children);
      } else {
        count++;
      }
    }
    return count;
  }

  Future<void> _downloadSelected() async {
    if (_selectedNodes.isEmpty) {
      setState(() {
        _statusMessage = '请先选择要下载的文件';
      });
      return;
    }

    if (_shareKey == null) {
      setState(() {
        _statusMessage = '请先解析分享链接';
      });
      return;
    }

    if (!_canDownload) {
      setState(() {
        _statusMessage = '当前链接仅支持预览，无法下载';
      });
      return;
    }

    // 选择下载目录
    setState(() {
      _statusMessage = '正在打开文件夹选择器...';
    });
    
    String? selectedDirectory;
    try {
      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择下载目录',
      );
      CloudDownloadLogger.download('文件夹选择器返回: $selectedDirectory');
    } catch (e) {
      setState(() {
        _statusMessage = '打开文件夹选择器失败: ${e.toString()}';
      });
      CloudDownloadLogger.error('文件夹选择器错误: $e');
      return;
    }
    
    if (selectedDirectory == null) {
      setState(() {
        _statusMessage = '未选择下载目录';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = '正在下载到: $selectedDirectory';
      _downloadedBytes = 0;
      _totalBytes = DownloadService.calculateTotalSize(_selectedNodes);
      _downloadProgress = 0.0;
      _currentFileName = '';
      _currentFileBytes = 0;
      _currentFileTotalBytes = 0;
    });

    try {
      // 计算总大小
      final totalSize = DownloadService.calculateTotalSize(_selectedNodes);
      CloudDownloadLogger.download('开始下载，总大小: ${DownloadService.formatSize(totalSize)}');

      await DownloadService.downloadSelected(
        _selectedNodes,
        _shareKey!,
        selectedDirectory,
        onProgress: (message) {
          setState(() {
            _statusMessage = message;
            // 从消息中提取当前文件名
            if (message.startsWith('正在下载: ')) {
              final parts = message.split(' ');
              if (parts.length >= 2) {
                _currentFileName = parts[1].split(' ')[0]; // 获取文件名（去掉百分比部分）
              }
            } else if (message.startsWith('下载完成: ')) {
              _currentFileName = '';
              _currentFileBytes = 0;
              _currentFileTotalBytes = 0;
            }
          });
        },
        onProgressBytes: (downloadedBytes, totalBytes) {
          setState(() {
            _downloadedBytes = downloadedBytes;
            _totalBytes = totalBytes;
            _downloadProgress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
          });
        },
      );

      setState(() {
        _isDownloading = false;
        _statusMessage = '下载完成！共下载 ${_selectedNodes.length} 个项目到: $selectedDirectory';
        _downloadedBytes = 0;
        _totalBytes = 0;
        _downloadProgress = 0.0;
        _currentFileName = '';
        _currentFileBytes = 0;
        _currentFileTotalBytes = 0;
      });

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = '下载失败: ${e.toString()}';
        _downloadedBytes = 0;
        _totalBytes = 0;
        _downloadProgress = 0.0;
        _currentFileName = '';
        _currentFileBytes = 0;
        _currentFileTotalBytes = 0;
      });
      CloudDownloadLogger.error('下载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('清华云盘下载'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 链接输入区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '分享链接',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        hintText: '请输入清华云盘分享链接，如: https://cloud.tsinghua.edu.cn/d/xxx/',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: (_isLoading || _isDownloading) ? null : _parseLink,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                      label: Text(_isLoading ? '解析中...' : '解析链接'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 状态信息
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDownloading ? Colors.orange[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDownloading ? Colors.orange[200]! : Colors.blue[200]!
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isDownloading) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isDownloading ? Colors.orange[800] : Colors.blue[800]
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 下载进度条
                  if (_isDownloading && _totalBytes > 0) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '下载进度: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${DownloadService.formatSize(_downloadedBytes)} / ${DownloadService.formatSize(_totalBytes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.orange[100],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 选中文件信息
            if (_selectedNodes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已选中 ${_selectedNodes.length} 个文件，总大小: ${_formatSelectedSize()}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_selectedNodes.isNotEmpty) const SizedBox(height: 16),
            
            // 文件树区域
            if (_fileNodes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '文件列表',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: (_selectedNodes.isEmpty || _isDownloading || !_canDownload) 
                      ? null 
                      : _downloadSelected,
                    icon: _isDownloading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                    label: Text(_isDownloading 
                      ? '下载中...' 
                      : _selectedNodes.isEmpty
                        ? '下载选中文件'
                        : '下载选中文件 (${_selectedNodes.length}个, ${_formatSelectedSize()})'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: FileTreeWidget(
                    nodes: _fileNodes,
                    onSelectionChanged: _onSelectionChanged,
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '暂无文件',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '请输入分享链接并点击解析',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}