import 'package:flutter/material.dart';
import '../../../core/localization/l10n_helper.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10nHelper.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings.title),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settings.languageSettings),
            subtitle: Text(l10n.settings.selectLanguage),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              LanguageSelector.show(context);
            },
          ),
          const Divider(),
          // Add more settings here
        ],
      ),
    );
  }
} 