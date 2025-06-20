import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n_helper.dart';
import '../providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = L10nHelper.of(context);

    return AlertDialog(
      title: Text(l10n.settings.languageSettings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: supportedLocales.map((locale) {
          return RadioListTile<Locale>(
            title: Text(localeNotifier.getLanguageName(locale)),
            value: locale,
            groupValue: currentLocale,
            onChanged: (Locale? value) {
              if (value != null) {
                localeNotifier.setLocale(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }
} 