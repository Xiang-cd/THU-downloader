import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_thu_dowloader/multiselect.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// https://cloud.tsinghua.edu.cn/d/a78bffdbc2e9453cbc9b/
class LinkDownload extends StatefulWidget {
  const LinkDownload({super.key});

  @override
  State<LinkDownload> createState() => _LinkDownload();
}

class _LinkDownload extends State<LinkDownload> {
  String currentLink = '';
  String _infoMessage = '';
  static const downloadUrlTemplate =
      'https://cloud.tsinghua.edu.cn/d/{shareId}/files/?p={filePath}&dl=1';
  static const rdownloadUrlTemplate =
      'https://cloud.tsinghua.edu.cn/d/{shareId}/files/?p={filePath}';
  static const direntUrlTemplate =
      'https://cloud.tsinghua.edu.cn/api/v2.1/share-links/{shareId}/dirents/?path={path}';

  List<String> items = [];
  List<int> selectedIndex = [];
  final linkController = TextEditingController();
  bool canDownload = true;


  MultiSelect multi_select = MultiSelect(
    items: [],
    onSelectionChanged: (List<int> selected) {},
  );
  String? getShareKey(String shareLink) {
    final RegExp regExp = RegExp(r"https://cloud\.tsinghua\.edu\.cn/d/(\w+)");
    final Match? match = regExp.firstMatch(shareLink);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  void _showMyDialog(BuildContext context, String title, String content) {
    // 创建一个简单的对话框
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          child: Text('ok'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // 展示对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _fetchData() async {
    // fetch basic info from the share link
    final shareKey = getShareKey(linkController.text);
    if (shareKey != null) {
      final response = await http.get(Uri.parse(linkController.text));
      canDownload =
          RegExp(r'canDownload: (.+?),').firstMatch(response.body)?.group(1) ==
              'true';

      if (response.statusCode == 404) {
        setState(() {
          _infoMessage = '内容不存在, T^T, 看看是不是链接输错了？';
        });
        return;
      } else if (response.statusCode == 500) {
        setState(() {
          _infoMessage = '服务暂时不可用，请稍后再试';
        });
        return;
      }

      print(canDownload);
      final direntUrl = direntUrlTemplate
          .replaceAll('{shareId}', shareKey)
          .replaceAll('{path}', '/');
      final direntResponse = await http.get(Uri.parse(direntUrl));
      if (direntResponse.statusCode != 200) {
        setState(() {
          _infoMessage = '获取文件列表失败，请稍后再试';
        });
        return;
      }
      final direntJsonList =
          json.decode(direntResponse.body)['dirent_list'] ?? [];
      print(direntJsonList);

      setState(() {
        currentLink = linkController.text;
        items = direntJsonList
            .map((e) => e['file_name'])
            .whereType<String>()
            .toList();
        multi_select = MultiSelect(items: items, onSelectionChanged: (List<int> selected) {
          setState(() {
            selectedIndex = selected;
          });
        });
        _infoMessage = canDownload
            ? 'parse success, can download'
            : 'parse success, preview only mode';
      });

      // open the download link in the browser
      // Process.run('open', [downloadLink]);
    } else {
      // alert the user that the link is invalid
      print('Invalid link');
      _showMyDialog(context, 'Invalid link', 'Please enter a valid link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('download from cloud.tsinghua.edu.cn shared links'),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_infoMessage, style: theme.textTheme.displayMedium),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'Enter the share link here',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      // clear button
                      icon: Icon(Icons.clear),
                      onPressed: () => linkController.clear(),
                    ),
                  ),
                ),
                // select path to download
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                        onPressed: () => _fetchData(),
                        child: Text('parse link')),
                    ElevatedButton(
                        onPressed: () => {print(selectedIndex)}, child: Text('download selected')),
                  ],
                ),
                SizedBox(height: 20),

                Expanded(child: multi_select)
              ],
            ),
          ),
        ));
  }
}
