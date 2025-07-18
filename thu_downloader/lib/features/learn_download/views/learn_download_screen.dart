import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thu_downloader/features/learn_download/utils/learn_api_service.dart';
import 'package:thu_downloader/features/learn_download/utils/learn_download_service.dart';
import 'package:thu_downloader/features/learn_download/views/webview_login_screen.dart';
import 'package:thu_downloader/features/learn_download/widgets/learn_file_tree_widget.dart';
import 'package:thu_downloader/features/learn_download/models/learn_file_tree_node.dart';
import '../../../core/localization/l10n_helper.dart';

class LearnDownloadScreen extends StatefulWidget {
  const LearnDownloadScreen({super.key});

  @override
  State<LearnDownloadScreen> createState() => _LearnDownloadScreenState();
}

class _LearnDownloadScreenState extends State<LearnDownloadScreen> with TickerProviderStateMixin {
  String _csrfToken = '';
  String _status = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isDownloading = false;
  late final LearnApiService _apiService;
  late final LearnDownloadService _downloadService;
  late TabController _tabController;
  
  // 文件树数据
  List<LearnFileTreeNode> _coursewareTree = [];
  // TODO: 实现作业和公告功能
  // List<LearnFileTreeNode> _homeworkTree = [];
  // List<LearnFileTreeNode> _announcementTree = [];
  
  // 选中的文件
  List<LearnFileTreeNode> _selectedDocuments = [];
  
  // 下载进度相关变量
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  double _downloadProgress = 0.0;
  int _completedCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _apiService = LearnApiService();
    _downloadService = LearnDownloadService(_apiService);
    _tabController = TabController(length: 3, vsync: this);
  }


  Future<void> _loadCoursewareTree() async {
    if (!_isLoggedIn) {
      setState(() {
        _status = 'Please login first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Loading courseware tree...';
    });

    try {
      final tree = await _downloadService.buildCoursewareTree(_csrfToken);
      setState(() {
        _coursewareTree = tree;
        _status = 'Courseware tree loaded successfully.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading courseware tree: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSelectionChanged(List<LearnFileTreeNode> selectedNodes) {
    setState(() {
      _selectedDocuments = selectedNodes;
    });
  }

  void _onNodeExpanded(LearnFileTreeNode node) {
    // TODO: 实现懒加载逻辑
  }

  // 计算选中文件的总大小
  int _calculateSelectedSize() {
    int totalSize = 0;
    for (var document in _selectedDocuments) {
      totalSize += document.size;
    }
    return totalSize;
  }

  // 格式化文件大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Future<void> _startDownload() async {
    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select files to download')),
      );
      return;
    }

    // 选择下载目录
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select download directory',
    );

    if (selectedDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No directory selected')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _status = 'Starting download...';
      _downloadedBytes = 0;
      _totalBytes = _calculateSelectedSize();
      _downloadProgress = 0.0;
      _completedCount = 0;
      _failedCount = 0;
    });

    try {
      // 顺序下载所有选中的文件
      for (int i = 0; i < _selectedDocuments.length; i++) {
        final document = _selectedDocuments[i];
        
        if (!mounted) break;
        
        setState(() {
          _status = 'Downloading: ${document.name} (${i + 1}/${_selectedDocuments.length})';
        });

        try {
          await _apiService.downloadFile(
            document,
            selectedDirectory,
            _csrfToken,
            onProgress: (downloaded, total) {
              if (mounted) {
                setState(() {
                  // 计算总体进度：已完成文件的字节数 + 当前文件已下载字节数
                  int completedBytes = 0;
                  for (int j = 0; j < i; j++) {
                    completedBytes += _selectedDocuments[j].size;
                  }
                  completedBytes += downloaded.toInt();
                  _downloadedBytes = completedBytes;
                  _downloadProgress = _totalBytes > 0 ? completedBytes / _totalBytes : 0.0;
                });
              }
            },
          );
          
          if (mounted) {
            setState(() {
              _completedCount++;
            });
          }
        } catch (e) {
          print('Error downloading ${document.name}: $e');
          if (mounted) {
            setState(() {
              _failedCount++;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          if (_failedCount == 0) {
            _status = 'Download completed successfully! ${_completedCount} files downloaded.';
          } else {
            _status = 'Download completed with errors. ${_completedCount} succeeded, ${_failedCount} failed.';
          }
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _status = 'Download failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    _downloadService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nHelper.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learnDownload.title),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '课件', icon: Icon(Icons.folder)),
            Tab(text: '作业', icon: Icon(Icons.assignment)),
            Tab(text: '公告', icon: Icon(Icons.announcement)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 登录区域
          if (!_isLoggedIn) _buildLoginSection(),
          
          // 状态信息
          if (_status.isNotEmpty) _buildStatusSection(),
          
          // 主要内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 课件Tab
                _buildCoursewareTab(),
                // 作业Tab
                _buildHomeworkTab(),
                // 公告Tab
                _buildAnnouncementTab(),
              ],
            ),
          ),
          
          // 下载按钮
          if (_isLoggedIn && _selectedDocuments.isNotEmpty)
            _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildLoginSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WebviewLoginScreen(
                            apiService: _apiService,
                            onLoginSuccess: (csrfToken) {
                              setState(() {
                                _csrfToken = csrfToken;
                                _status = 'Login successful! Token: ${csrfToken.substring(0, 10)}...';
                                _isLoggedIn = true;
                              });
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        _status = 'Webview error: $e';
                      });
                    }
                  },
                  child: const Text('Login with Webview'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
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
                  _status,
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
                      'Progress: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_formatSize(_downloadedBytes)} / ${_formatSize(_totalBytes)}',
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
                if (_completedCount > 0 || _failedCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_completedCount > 0) ...[
                        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Completed: $_completedCount',
                          style: TextStyle(fontSize: 12, color: Colors.green[700]),
                        ),
                      ],
                      if (_failedCount > 0) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.error, size: 16, color: Colors.red[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Failed: $_failedCount',
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoursewareTab() {
    return Column(
      children: [
        // 加载按钮
        if (_isLoggedIn && _coursewareTree.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loadCoursewareTree,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load Courseware Tree'),
            ),
          ),
        
        // 文件树
        Expanded(
          child: _coursewareTree.isEmpty
              ? const Center(
                  child: Text('No courseware data available'),
                )
              : LearnFileTreeWidget(
                  nodes: _coursewareTree,
                  onSelectionChanged: _onSelectionChanged,
                  onNodeExpanded: _onNodeExpanded,
                ),
        ),
      ],
    );
  }

  Widget _buildHomeworkTab() {
    return const Center(
      child: Text('Homework download feature coming soon...'),
    );
  }

  Widget _buildAnnouncementTab() {
    return const Center(
      child: Text('Announcement download feature coming soon...'),
    );
  }

  Widget _buildDownloadButton() {
    final stats = _downloadService.getSelectionStats(_coursewareTree);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Selected: ${stats['fileCount']} files (${stats['formattedTotalSize']})',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _startDownload,
                icon: _isDownloading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
                label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 