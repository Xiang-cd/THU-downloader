import 'package:flutter/material.dart';

// Multi Select widget
// This widget is reusable
class MultiSelect extends StatefulWidget {
  final List<String> items;
  const MultiSelect({super.key, required this.items});

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
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
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
    );
  }
}
