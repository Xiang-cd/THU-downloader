#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// ARB文件合并脚本
/// 将多个模块的ARB文件合并成单一文件
void main() async {
  const sourceDir = 'lib/l10n/modules';
  const targetDir = 'lib/l10n';
  
  // 支持的语言列表
  const locales = ['en', 'zh'];
  
  for (final locale in locales) {
    await mergeArbFiles(locale, sourceDir, targetDir);
  }
  
  print('✅ ARB文件合并完成！');
}

Future<void> mergeArbFiles(String locale, String sourceDir, String targetDir) async {
  // 模块文件模式
  final moduleFiles = [
    'common_$locale.arb',
    'navigation_$locale.arb', 
    'cloud_download_$locale.arb',
    'learn_download_$locale.arb',
    'settings_$locale.arb',
  ];
  
  final mergedData = <String, dynamic>{};
  mergedData['@@locale'] = locale;
  
  // 合并所有模块文件
  for (final fileName in moduleFiles) {
    final file = File('$sourceDir/$fileName');
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // 移除@@locale key，避免重复
      data.remove('@@locale');
      
      // 合并到主数据
      mergedData.addAll(data);
      
      print('📄 合并: $fileName');
    }
  }
  
  // 写入合并后的文件
  final outputFile = File('$targetDir/app_$locale.arb');
  final encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString(encoder.convert(mergedData));
  
  print('✅ 生成: app_$locale.arb (${mergedData.length - 1} 个key)');
} 