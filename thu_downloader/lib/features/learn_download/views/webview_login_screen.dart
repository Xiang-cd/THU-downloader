import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/learn_api_service.dart';

class WebviewLoginScreen extends StatefulWidget {
  final Function(String csrfToken) onLoginSuccess;

  const WebviewLoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<WebviewLoginScreen> createState() => _WebviewLoginScreenState();
}

class _WebviewLoginScreenState extends State<WebviewLoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
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
              _isLoading = true;
              _status = 'Loading...';
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
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
              _handleTicketRedirect(request.url);
              return NavigationDecision.prevent;
            }
            
            // 拦截learn.tsinghua.edu.cn的登录成功页面
            if (request.url.contains('learn.tsinghua.edu.cn') && 
                request.url.contains('course/student')) {
              _handleLearnLoginSuccess();
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

  void _handleTicketRedirect(String url) {
    setState(() {
      _status = 'Processing ticket...';
    });

    // 解析URL中的ticket参数
    final uri = Uri.parse(url);
    final ticket = uri.queryParameters['ticket'];
    
    if (ticket != null) {
      _completeAuthentication(ticket);
    } else {
      setState(() {
        _status = 'Failed to extract ticket from URL';
      });
    }
  }

  void _handleLearnLoginSuccess() {
    setState(() {
      _status = 'Login successful, extracting CSRF token...';
    });
    
    // 从webview的cookies中提取CSRF token
    _extractCsrfToken();
  }

  Future<void> _completeAuthentication(String ticket) async {
    setState(() {
      _status = 'Completing authentication...';
    });

    try {
      final apiService = LearnApiService();
      final csrfToken = await apiService.completeSsoLogin(ticket);
      
      if (csrfToken != null) {
        widget.onLoginSuccess(csrfToken);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _status = 'Failed to complete authentication';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _extractCsrfToken() async {
    try {
      // 获取webview的cookies
      final cookies = await _controller.runJavaScriptReturningResult(
        'document.cookie'
      ) as String;
      
      // 解析XSRF-TOKEN
      final csrfToken = _extractCsrfFromCookies(cookies);
      
      if (csrfToken != null) {
        widget.onLoginSuccess(csrfToken);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _status = 'Failed to extract CSRF token from cookies';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error extracting CSRF token: $e';
      });
    }
  }

  String? _extractCsrfFromCookies(String cookies) {
    final cookiePairs = cookies.split(';');
    for (final pair in cookiePairs) {
      final trimmed = pair.trim();
      if (trimmed.startsWith('XSRF-TOKEN=')) {
        return trimmed.substring('XSRF-TOKEN='.length);
      }
    }
    return null;
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