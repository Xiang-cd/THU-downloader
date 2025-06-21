import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/localization/l10n_helper.dart';
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
  final GlobalKey<FileTreeWidgetState> _fileTreeKey = GlobalKey<FileTreeWidgetState>();
  List<FileTreeNode> _fileNodes = [];
  List<FileTreeNode> _selectedNodes = [];
  String _statusMessage = '';
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _shareKey;
  bool _canDownload = false;
  
  // 下载进度相关变量
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  double _downloadProgress = 0.0;

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
    final l10n = L10nHelper.of(context);
    
    if (_linkController.text.isEmpty) {
      setState(() {
        _statusMessage = l10n.cloudDownload.enterShareLink;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = l10n.cloudDownload.validatingLink;
      _fileNodes = [];
      _selectedNodes = [];
      _shareKey = null;
      _canDownload = false;
    });

    try {
      // 验证分享链接
      final linkInfo = await CloudApiService.validateShareLink(_linkController.text);
      
      setState(() {
        _statusMessage = l10n.cloudDownload.linkValidatedGettingTree;
        _shareKey = linkInfo.shareKey;
        _canDownload = linkInfo.canDownload;
      });

      // 递归获取完整的文件树
      final fileTree = await CloudApiService.getFileTree(linkInfo.shareKey);
      
      setState(() {
        _isLoading = false;
        _fileNodes = fileTree;
        _statusMessage = _canDownload 
          ? l10n.cloudDownload.parseSuccessCanDownload(_countTotalFiles(fileTree))
          : l10n.cloudDownload.parseSuccessPreviewOnly(_countTotalFiles(fileTree));
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = l10n.cloudDownload.parseFailed(e.toString());
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
    final l10n = L10nHelper.of(context);
    
    if (_selectedNodes.isEmpty) {
      setState(() {
        _statusMessage = l10n.cloudDownload.selectFilesFirst;
      });
      return;
    }

    if (_shareKey == null) {
      setState(() {
        _statusMessage = l10n.cloudDownload.parseLinkFirst;
      });
      return;
    }

    if (!_canDownload) {
      setState(() {
        _statusMessage = l10n.cloudDownload.previewOnlyNoDownload;
      });
      return;
    }

    // 选择下载目录
    setState(() {
      _statusMessage = l10n.cloudDownload.openingFolderPicker;
    });
    
    String? selectedDirectory;
    try {
      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.cloudDownload.selectDownloadDirectory,
      );
      CloudDownloadLogger.download('文件夹选择器返回: $selectedDirectory');
    } catch (e) {
      setState(() {
        _statusMessage = l10n.cloudDownload.folderPickerFailed(e.toString());
      });
      CloudDownloadLogger.error('文件夹选择器错误: $e');
      return;
    }
    
    if (selectedDirectory == null) {
      setState(() {
        _statusMessage = l10n.cloudDownload.noDirectorySelected;
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = l10n.cloudDownload.downloadingTo(selectedDirectory!);
      _downloadedBytes = 0;
      _totalBytes = DownloadService.calculateTotalSize(_selectedNodes);
      _downloadProgress = 0.0;
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
        if (DownloadService.isCancelled) {
          _statusMessage = l10n.cloudDownload.downloadCancelled;
        } else {
          _statusMessage = l10n.cloudDownload.downloadCompleted(_selectedNodes.length, selectedDirectory!);
        }
        _downloadedBytes = 0;
        _totalBytes = 0;
        _downloadProgress = 0.0;
      });

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = l10n.cloudDownload.downloadFailed(e.toString());
        _downloadedBytes = 0;
        _totalBytes = 0;
        _downloadProgress = 0.0;
      });
      CloudDownloadLogger.error('下载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nHelper.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cloudDownload.title),
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
                    Text(
                      l10n.cloudDownload.shareLinkLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: l10n.cloudDownload.shareLinkHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.link),
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
                      label: Text(_isLoading ? l10n.cloudDownload.parsing : l10n.cloudDownload.parseLink),
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
                            _statusMessage.isEmpty ? l10n.cloudDownload.enterShareLink : _statusMessage,
                            style: TextStyle(
                              color: _isDownloading ? Colors.orange[800] : Colors.blue[800]
                            ),
                          ),
                        ),
                        if (_isDownloading) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              DownloadService.cancelDownload();
                              setState(() {
                                _statusMessage = l10n.cloudDownload.cancellingDownload;
                              });
                            },
                            icon: Icon(Icons.cancel, color: Colors.orange[700], size: 18),
                            label: Text(
                              l10n.cloudDownload.cancelDownload,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
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
                              l10n.cloudDownload.downloadProgress((_downloadProgress * 100).toStringAsFixed(1)),
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
                        l10n.cloudDownload.selectedFiles(_selectedNodes.length, _formatSelectedSize()),
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
                  Row(
                    children: [
                                          Text(
                      l10n.cloudDownload.fileList,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _isDownloading ? null : () {
                          if (_fileTreeKey.currentState != null) {
                            if (_selectedNodes.isEmpty) {
                              _fileTreeKey.currentState!.selectAll();
                            } else {
                              _fileTreeKey.currentState!.deselectAll();
                            }
                          }
                        },
                        icon: Icon(
                          _selectedNodes.isEmpty ? Icons.select_all : Icons.deselect,
                          size: 18,
                        ),
                        label: Text(_selectedNodes.isEmpty ? l10n.cloudDownload.selectAll : l10n.cloudDownload.deselectAll),
                      ),
                    ],
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
                      ? l10n.cloudDownload.downloading
                      : _selectedNodes.isEmpty
                        ? l10n.cloudDownload.downloadSelectedFiles
                        : l10n.cloudDownload.downloadSelectedFilesWithCount(_selectedNodes.length, _formatSelectedSize())),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: FileTreeWidget(
                    key: _fileTreeKey,
                    nodes: _fileNodes,
                    onSelectionChanged: _onSelectionChanged,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.cloudDownload.noFiles,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
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