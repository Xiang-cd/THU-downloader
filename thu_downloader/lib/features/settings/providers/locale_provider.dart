import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 支持的语言列表
const supportedLocales = [
  Locale('zh', ''), // 中文
  Locale('en', ''), // 英文
];

// 语言提供器
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('zh', '')) {
    _loadLocale();
  }

  // 从本地存储加载语言设置
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'zh';
    final countryCode = prefs.getString('country_code') ?? '';
    
    final locale = Locale(languageCode, countryCode);
    if (supportedLocales.contains(locale)) {
      state = locale;
    }
  }

  // 设置语言
  Future<void> setLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      state = locale;
      
      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');
    }
  }

  // 获取语言显示名称
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
} 