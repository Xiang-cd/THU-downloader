import 'package:flutter/material.dart';
import '../models/file_tree_node.dart';

class FileTreeWidget extends StatefulWidget {
  final List<FileTreeNode> nodes;
  final Function(List<FileTreeNode>) onSelectionChanged;

  const FileTreeWidget({
    super.key,
    required this.nodes,
    required this.onSelectionChanged,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  late List<FileTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = widget.nodes;
  }

  void _toggleExpansion(FileTreeNode node) {
    setState(() {
      _updateNodeInTree(node, node.copyWith(isExpanded: !node.isExpanded));
    });
  }

  void _toggleSelection(FileTreeNode node) {
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

  void _selectAllChildren(FileTreeNode node) {
    for (var child in node.children) {
      _updateNodeInTree(child, child.copyWith(
        isSelected: true,
        isPartiallySelected: false,
      ));
      _selectAllChildren(child);
    }
  }

  void _deselectAllChildren(FileTreeNode node) {
    for (var child in node.children) {
      _updateNodeInTree(child, child.copyWith(
        isSelected: false,
        isPartiallySelected: false,
      ));
      _deselectAllChildren(child);
    }
  }

  void _updateParentSelection() {
    // 这里简化处理，实际应该递归更新所有父节点
    for (var node in _nodes) {
      _updateNodeSelectionState(node);
    }
  }

  void _updateNodeSelectionState(FileTreeNode node) {
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

  void _updateNodeInTree(FileTreeNode targetNode, FileTreeNode newNode) {
    // 这里简化处理，实际应该递归查找并更新节点
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i] == targetNode) {
        _nodes[i] = newNode;
        return;
      }
      _updateNodeInChildren(_nodes[i], targetNode, newNode);
    }
  }

  void _updateNodeInChildren(FileTreeNode parent, FileTreeNode targetNode, FileTreeNode newNode) {
    for (int i = 0; i < parent.children.length; i++) {
      if (parent.children[i] == targetNode) {
        parent.children[i] = newNode;
        return;
      }
      _updateNodeInChildren(parent.children[i], targetNode, newNode);
    }
  }

  List<FileTreeNode> _getSelectedNodes() {
    List<FileTreeNode> selected = [];
    _collectSelectedNodes(_nodes, selected);
    return selected;
  }

  void _collectSelectedNodes(List<FileTreeNode> nodes, List<FileTreeNode> selected) {
    for (var node in nodes) {
      // 只统计被选中的文件，不统计文件夹
      if (node.isSelected && !node.isDirectory) {
        selected.add(node);
      }
      _collectSelectedNodes(node.children, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _nodes.map((node) => _buildTreeNode(node, 0)).toList(),
    );
  }

  Widget _buildTreeNode(FileTreeNode node, int depth) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: ListTile(
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (node.isDirectory)
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
                Checkbox(
                  value: node.isPartiallySelected ? null : node.isSelected,
                  tristate: true,
                  onChanged: (_) => _toggleSelection(node),
                ),
              ],
            ),
            title: Row(
              children: [
                Icon(
                  node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  color: node.isDirectory ? Colors.amber : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (!node.isDirectory)
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
              if (node.isDirectory) {
                _toggleExpansion(node);
              } else {
                _toggleSelection(node);
              }
            },
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
} 