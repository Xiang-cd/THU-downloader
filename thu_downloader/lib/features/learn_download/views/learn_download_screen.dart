import 'package:flutter/material.dart';
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
    // 这里可以实现懒加载逻辑
    print('Node expanded: ${node.name}');
  }

  void _startDownload() {
    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select files to download')),
      );
      return;
    }

    // TODO: 实现下载逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download of ${_selectedDocuments.length} files...'),
      ),
    );
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
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_status, style: TextStyle(color: Colors.grey[600])),
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
                onPressed: _startDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
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