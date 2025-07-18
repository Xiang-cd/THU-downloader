import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/learn_api_service.dart';

class WebviewLoginScreen extends StatefulWidget {
  final Function(String csrfToken) onLoginSuccess;
  final LearnApiService apiService;

  const WebviewLoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.apiService,
  });

  @override
  State<WebviewLoginScreen> createState() => _WebviewLoginScreenState();
}

class _WebviewLoginScreenState extends State<WebviewLoginScreen> {
  late final WebViewController _controller;
  String _status = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _status = 'Loading...';
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _status = 'Error: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // 拦截重定向URL，提取ticket
            if (request.url.contains('ticket=')) {
              _completeAuthentication(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://id.tsinghua.edu.cn/do/off/ui/auth/login/form/bb5df85216504820be7bba2b0ae1535b/0'),
      );
  }


  Future<void> _completeAuthentication(String url) async {
    setState(() {
      _status = 'Completing authentication...';
    });
    try {
      final csrfToken = await widget.apiService.completeSsoLogin(url);
      if (csrfToken != null) {
        widget.onLoginSuccess(csrfToken);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _status = 'Failed to complete authentication';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Tsinghua Learn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                // 防止键盘事件冲突
              },
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
} 