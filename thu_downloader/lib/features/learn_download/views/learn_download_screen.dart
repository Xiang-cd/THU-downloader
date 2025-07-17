import 'package:flutter/material.dart';
import 'package:thu_downloader/features/learn_download/utils/learn_api_service.dart';
import 'package:thu_downloader/features/learn_download/views/webview_login_screen.dart';
import '../../../core/localization/l10n_helper.dart';

class LearnDownloadScreen extends StatefulWidget {
  const LearnDownloadScreen({super.key});

  @override
  State<LearnDownloadScreen> createState() => _LearnDownloadScreenState();
}

class _LearnDownloadScreenState extends State<LearnDownloadScreen> {
  final _tokenController = TextEditingController();
  String _status = '';
  bool _isLoading = false;
  late final LearnApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = LearnApiService();
  }

  Future<void> _testToken() async {
    if (_tokenController.text.isEmpty) {
      setState(() {
        _status = 'Please enter a token.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
    });

    try {
      final success = await _apiService.testApi(_tokenController.text);
      setState(() {
        _status = success ? 'Token is valid!' : 'Token is invalid.';
      });
    } catch (e) {
      setState(() {
        _status = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nHelper.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learnDownload.title),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Enter _csrf Token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testToken,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Token'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WebviewLoginScreen(
                        onLoginSuccess: (csrfToken) {
                          setState(() {
                            _tokenController.text = csrfToken;
                            _status = 'Login successful! Token: ${csrfToken.substring(0, 10)}...';
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
            const SizedBox(height: 16),
            if (_status.isNotEmpty) Text(_status),
          ],
        ),
      ),
    );
  }
} 