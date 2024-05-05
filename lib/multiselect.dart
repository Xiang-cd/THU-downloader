import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Multi Select widget
// This widget is reusable
class MultiSelect extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<int>> onSelectionChanged; // Callback function
  MultiSelect({super.key, required this.items, required this.onSelectionChanged});


  @override
  State<StatefulWidget> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  // this variable holds the selected items
  List<int> selectedIdex = [];
// This function is triggered when a checkbox is checked or unchecked
  void _itemChange(int itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedIdex.add(itemValue);
      } else {
        selectedIdex.remove(itemValue);
      }
      widget.onSelectionChanged(selectedIdex);
    });
  }

  void _selectAll() => setState(() {
        selectedIdex =
            List<int>.generate(widget.items.length, (index) => index);
            widget.onSelectionChanged(selectedIdex);
      });

  void _deselectAll() => setState(() {
        selectedIdex = [];
        widget.onSelectionChanged(selectedIdex);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          ElevatedButton(
            onPressed: _selectAll,
            child: Text('Select All'),
          ),
          ElevatedButton(
            onPressed: _deselectAll,
            child: Text('Deselect All'),
          ),
        ],
      ),
      Expanded(
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, int index) {
            final item = widget.items[index];
            return CheckboxListTile(
              value: selectedIdex.contains(index),
              title: Text(item),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (isChecked) => _itemChange(index, isChecked!),
            );
          },
        ),
      )
    ]));
  }
}
