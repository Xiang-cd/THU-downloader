 # 多语言支持说明

## 概述
本项目使用Flutter官方的国际化方案来支持多语言。

## 支持的语言
- 中文 (zh)
- 英文 (en)

## 添加新语言的步骤

### 1. 创建新的ARB文件
在 `lib/l10n/` 目录下创建新的ARB文件，例如 `app_ja.arb` (日语)：

```json
{
  "@@locale": "ja",
  "appTitle": "THU ダウンローダー",
  "cloudDownloadTitle": "クラウドダウンロード",
  ...
}
```

### 2. 更新支持的语言列表
在 `lib/features/settings/providers/locale_provider.dart` 中添加新语言：

```dart
const supportedLocales = [
  Locale('zh', ''), // 中文
  Locale('en', ''), // 英文
  Locale('ja', ''), // 日语 - 新添加
];
```

### 3. 更新语言显示名称
在 `LocaleNotifier` 类的 `getLanguageName` 方法中添加新语言：

```dart
String getLanguageName(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return '中文';
    case 'en':
      return 'English';
    case 'ja':
      return '日本語'; // 新添加
    default:
      return locale.languageCode;
  }
}
```

### 4. 重新生成本地化文件
运行以下命令：

```bash
flutter gen-l10n
```

## 使用方法

### 在代码中使用本地化字符串
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle)
```

### 带参数的本地化字符串
在ARB文件中定义：
```json
{
  "parseSuccessCanDownload": "Parse successful, found {count} files, downloadable",
  "@parseSuccessCanDownload": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

在代码中使用：
```dart
Text(l10n.parseSuccessCanDownload(fileCount))
```

# 🗂 ARB文件分离完整方案

## 🎯 概述

本项目实现了模块化的ARB文件管理，将大型ARB文件分离成多个小模块，便于团队协作和维护。

## 📁 文件结构

```
lib/l10n/
├── modules/                    # 🎯 模块化ARB文件 (源文件)
│   ├── common_en.arb          # 通用模块 - 英文
│   ├── common_zh.arb          # 通用模块 - 中文
│   ├── navigation_en.arb      # 导航模块 - 英文
│   ├── navigation_zh.arb      # 导航模块 - 中文
│   ├── cloud_download_en.arb  # 云盘下载模块 - 英文
│   ├── cloud_download_zh.arb  # 云盘下载模块 - 中文
│   ├── learn_download_en.arb  # 学堂下载模块 - 英文
│   ├── learn_download_zh.arb  # 学堂下载模块 - 中文
│   ├── settings_en.arb        # 设置模块 - 英文
│   └── settings_zh.arb        # 设置模块 - 中文
├── app_en.arb                 # 🤖 合并后的英文文件 (自动生成)
├── app_zh.arb                 # 🤖 合并后的中文文件 (自动生成)
└── l10n.yaml                  # 配置文件
scripts/
└── merge_arb.dart             # 🔧 ARB合并脚本
Makefile                       # 🚀 便捷命令
```

## 🛠 工作流程

### 1. 开发时编辑 (开发者操作)
```bash
# 编辑模块文件
vim lib/l10n/modules/cloud_download_zh.arb
vim lib/l10n/modules/cloud_download_en.arb
```

### 2. 构建本地化 (一键命令)
```bash
# 完整构建 (推荐)
make build-l10n

# 或者分步骤
make merge-arb    # 1. 合并模块文件
make gen-l10n     # 2. 生成Flutter本地化
```

### 3. 提交代码 (版本控制)
```bash
# 同时提交源文件和生成文件
git add lib/l10n/modules/
git add lib/l10n/app_*.arb
git commit -m "feat: 添加新的国际化文本"
```

## 🎨 模块化的优势

### ✅ **开发体验**
- **独立编辑**: 每个功能模块有独立的ARB文件
- **避免冲突**: 不同开发者可以同时编辑不同模块
- **清晰分组**: 一目了然每个文本属于哪个功能

### ✅ **维护管理**
- **责任明确**: 每个模块由对应团队维护
- **版本控制**: 可以独立追踪每个模块的变更历史
- **批量操作**: 可以批量处理某个模块的翻译

### ✅ **团队协作**
- **并行开发**: 新功能开发时创建新模块文件
- **翻译分工**: 不同语言的翻译可以并行进行
- **代码审查**: PR时可以清楚看到具体模块的变更

## 📝 添加新模块的步骤

### 1. 创建新模块文件
```bash
# 创建新功能模块 (例如: 新增文件管理功能)
cat > lib/l10n/modules/file_manager_en.arb << 'EOF'
{
  "@@locale": "en",
  "fileManager_title": "File Manager",
  "fileManager_createFolder": "Create Folder",
  "fileManager_deleteFile": "Delete File"
}
EOF

cat > lib/l10n/modules/file_manager_zh.arb << 'EOF'
{
  "@@locale": "zh",
  "fileManager_title": "文件管理",
  "fileManager_createFolder": "创建文件夹", 
  "fileManager_deleteFile": "删除文件"
}
EOF
```

### 2. 更新合并脚本
```dart
// 在 scripts/merge_arb.dart 中添加新模块
final moduleFiles = [
  'common_$locale.arb',
  'navigation_$locale.arb', 
  'cloud_download_$locale.arb',
  'learn_download_$locale.arb',
  'settings_$locale.arb',
  'file_manager_$locale.arb',  // 🆕 新增
];
```

### 3. 更新Helper类
```dart
// 在 L10nHelper 中添加新分组
class L10nHelper {
  // ... existing code ...
  FileManagerStrings get fileManager => FileManagerStrings(_l10n);
}

class FileManagerStrings {
  final AppLocalizations _l10n;
  FileManagerStrings(this._l10n);
  
  String get title => _l10n.fileManager_title;
  String get createFolder => _l10n.fileManager_createFolder;
  String get deleteFile => _l10n.fileManager_deleteFile;
}
```

### 4. 构建和使用
```bash
# 重新构建
make build-l10n

# 在代码中使用
final l10n = L10nHelper.of(context);
Text(l10n.fileManager.title)
```

## 🔧 常用命令

```bash
# 🚀 快速命令
make help              # 查看所有可用命令
make show-structure    # 查看文件结构
make build-l10n        # 完整构建 (最常用)

# 🔍 调试命令
make merge-arb         # 仅合并，查看合并结果
make gen-l10n          # 仅生成，测试Flutter集成
make clean-l10n        # 清理，重新开始

# 📊 统计信息
find lib/l10n/modules -name "*.arb" | wc -l    # 模块文件数量
grep -r "@@locale" lib/l10n/modules            # 检查locale标识
```

## 🎪 其他方案对比

### 方案A: 当前方案 (合并脚本)
✅ **优势**: 模块化开发 + Flutter官方支持  
❌ **劣势**: 需要构建步骤

### 方案B: easy_localization
✅ **优势**: 原生支持嵌套JSON  
❌ **劣势**: 第三方依赖，类型安全较弱

### 方案C: 单一大文件
✅ **优势**: 无需构建步骤  
❌ **劣势**: 难以维护，容易冲突

## 🎯 最佳实践

### 📏 **命名约定**
- 模块前缀: `moduleName_`
- 驼峰命名: `moduleName_actionName` 
- 有意义: `cloudDownload_parseLink` ✅ 而非 `cd_pl` ❌

### 📂 **文件组织**
- 按功能分模块，不按页面
- 通用文本放在 `common_*.arb`
- 模块文件保持适中大小 (< 50个key)

### 🔄 **开发流程**
1. 先编辑模块文件
2. 运行 `make build-l10n`
3. 提交源文件和生成文件
4. 在代码中使用 `L10nHelper.of(context).module.key`

### 🧪 **CI/CD集成**
```yaml
# 在 GitHub Actions 中
- name: Build Localization
  run: |
    cd thu_downloader
    make build-l10n
    
- name: Check for changes
  run: |
    if [[ `git status --porcelain` ]]; then
      echo "❌ ARB文件需要重新构建！"
      exit 1
    fi
```

## 🎉 总结

这个方案完美解决了你提出的多级dict需求：

🎯 **模块化**: 每个功能有独立的ARB文件  
🎯 **分组管理**: Helper类提供清晰的API  
🎯 **团队协作**: 不同模块可以并行开发  
🎯 **类型安全**: 保持Flutter官方方案的优势  
🎯 **自动化**: 一键构建，无需手工维护  

现在你可以愉快地进行模块化的国际化开发了！🚀