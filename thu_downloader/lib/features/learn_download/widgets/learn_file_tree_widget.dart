import 'package:flutter/material.dart';
import '../models/learn_file_tree_node.dart';

class LearnFileTreeWidget extends StatefulWidget {
  final List<LearnFileTreeNode> nodes;
  final Function(List<LearnFileTreeNode>) onSelectionChanged;
  final Function(LearnFileTreeNode) onNodeExpanded;

  const LearnFileTreeWidget({
    super.key,
    required this.nodes,
    required this.onSelectionChanged,
    required this.onNodeExpanded,
  });

  @override
  State<LearnFileTreeWidget> createState() => LearnFileTreeWidgetState();
}

class LearnFileTreeWidgetState extends State<LearnFileTreeWidget> {
  late List<LearnFileTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = widget.nodes;
  }

  @override
  void didUpdateWidget(LearnFileTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes != widget.nodes) {
      _nodes = widget.nodes;
    }
  }

  // 全选所有文件
  void selectAll() {
    setState(() {
      for (var node in _nodes) {
        _updateNodeInTree(node, node.copyWith(
          isSelected: true,
          isPartiallySelected: false,
        ));
        _selectAllChildren(node);
      }
    });
    widget.onSelectionChanged(_getSelectedNodes());
  }

  // 取消全选
  void deselectAll() {
    setState(() {
      for (var node in _nodes) {
        _updateNodeInTree(node, node.copyWith(
          isSelected: false,
          isPartiallySelected: false,
        ));
        _deselectAllChildren(node);
      }
    });
    widget.onSelectionChanged(_getSelectedNodes());
  }

  void _toggleExpansion(LearnFileTreeNode node) {
    setState(() {
      _updateNodeInTree(node, node.copyWith(isExpanded: !node.isExpanded));
    });
    widget.onNodeExpanded(node);
  }

  void _toggleSelection(LearnFileTreeNode node) {
    setState(() {
      final newSelected = !node.isSelected;
      _updateNodeInTree(node, node.copyWith(
        isSelected: newSelected,
        isPartiallySelected: false,
      ));
      
      // 如果选中，则选中所有子节点
      if (newSelected) {
        _selectAllChildren(node);
      } else {
        _deselectAllChildren(node);
      }
      
      // 更新父节点的选中状态
      _updateParentSelection();
    });
    
    widget.onSelectionChanged(_getSelectedNodes());
  }

  void _selectAllChildren(LearnFileTreeNode node) {
    for (var child in node.children) {
      _updateNodeInTree(child, child.copyWith(
        isSelected: true,
        isPartiallySelected: false,
      ));
      _selectAllChildren(child);
    }
  }

  void _deselectAllChildren(LearnFileTreeNode node) {
    for (var child in node.children) {
      _updateNodeInTree(child, child.copyWith(
        isSelected: false,
        isPartiallySelected: false,
      ));
      _deselectAllChildren(child);
    }
  }

  void _updateParentSelection() {
    // 递归更新所有父节点的状态
    for (var node in _nodes) {
      _updateNodeSelectionState(node);
    }
  }

  void _updateNodeSelectionState(LearnFileTreeNode node) {
    // 先递归处理所有子节点
    for (var child in node.children) {
      _updateNodeSelectionState(child);
    }
    
    // 然后更新当前节点的状态
    if (node.children.isEmpty) return; // 叶子节点不需要更新
    
    final selectedChildren = node.children.where((child) => child.isSelected).length;
    final partiallySelectedChildren = node.children.where((child) => child.isPartiallySelected).length;
    
    if (selectedChildren == node.children.length && partiallySelectedChildren == 0) {
      // 所有子节点都被选中，且没有部分选中的
      _updateNodeInTree(node, node.copyWith(
        isSelected: true,
        isPartiallySelected: false,
      ));
    } else if (selectedChildren > 0 || partiallySelectedChildren > 0) {
      // 有部分子节点被选中，或有部分选中的子节点
      _updateNodeInTree(node, node.copyWith(
        isSelected: false,
        isPartiallySelected: true,
      ));
    } else {
      // 没有子节点被选中
      _updateNodeInTree(node, node.copyWith(
        isSelected: false,
        isPartiallySelected: false,
      ));
    }
  }

  void _updateNodeInTree(LearnFileTreeNode targetNode, LearnFileTreeNode newNode) {
    // 递归查找并更新节点
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i] == targetNode) {
        _nodes[i] = newNode;
        return;
      }
      _updateNodeInChildren(_nodes[i], targetNode, newNode);
    }
  }

  void _updateNodeInChildren(LearnFileTreeNode parent, LearnFileTreeNode targetNode, LearnFileTreeNode newNode) {
    for (int i = 0; i < parent.children.length; i++) {
      if (parent.children[i] == targetNode) {
        parent.children[i] = newNode;
        return;
      }
      _updateNodeInChildren(parent.children[i], targetNode, newNode);
    }
  }

  List<LearnFileTreeNode> _getSelectedNodes() {
    List<LearnFileTreeNode> selected = [];
    _collectSelectedNodes(_nodes, selected);
    return selected;
  }

  void _collectSelectedNodes(List<LearnFileTreeNode> nodes, List<LearnFileTreeNode> selected) {
    for (var node in nodes) {
      // 只统计被选中的文档，不统计文件夹
      if (node.isSelected && node.type == NodeType.document) {
        selected.add(node);
      }
      _collectSelectedNodes(node.children, selected);
    }
  }

  // 获取选中文件的统计信息
  Map<String, dynamic> getSelectionStats() {
    final selectedNodes = _getSelectedNodes();
    int totalSize = 0;
    int fileCount = selectedNodes.length;
    
    for (var node in selectedNodes) {
      totalSize += node.size;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 统计信息栏
        _buildStatsBar(),
        // 文件树列表
        Expanded(
          child: ListView(
            children: _nodes.map((node) => _buildTreeNode(node, 0)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final stats = getSelectionStats();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Text(
            '已选择 ${stats['fileCount']} 个文件',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Text(
            '总大小: ${stats['formattedTotalSize']}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: selectAll,
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: deselectAll,
            child: const Text('取消全选'),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(LearnFileTreeNode node, int depth) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: ListTile(
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (node.type != NodeType.document)
                  IconButton(
                    icon: Icon(
                      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: () => _toggleExpansion(node),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  )
                else
                  const SizedBox(width: 20),
                if (node.type == NodeType.document)
                  Checkbox(
                    value: node.isPartiallySelected ? null : node.isSelected,
                    tristate: true,
                    onChanged: (_) => _toggleSelection(node),
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
            title: Row(
              children: [
                Text(
                  node.iconName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.type == NodeType.document && node.formattedUploadTime.isNotEmpty)
                        Text(
                          node.formattedUploadTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (node.type != NodeType.document)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        node.formattedTotalSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${node.fileCount} 个文件',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    node.formattedSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            onTap: () {
              if (node.type != NodeType.document) {
                _toggleExpansion(node);
              } else {
                _toggleSelection(node);
              }
            },
          ),
        ),
        if (node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
} 