import 'package:flutter/material.dart';
import '../../../core/localization/l10n_helper.dart';

class LearnDownloadScreen extends StatelessWidget {
  const LearnDownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10nHelper.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learnDownload.title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(l10n.learnDownload.inDevelopment),
      ),
    );
  }
} 