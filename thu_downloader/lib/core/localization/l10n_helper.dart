import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';

/// 本地化帮助类，提供分组的API接口
class L10nHelper {
  final AppLocalizations _l10n;
  
  L10nHelper(this._l10n);
  
  static L10nHelper of(BuildContext context) {
    return L10nHelper(AppLocalizations.of(context)!);
  }
  
  /// 应用级别的文本
  AppStrings get app => AppStrings(_l10n);
  
  /// 导航相关的文本
  NavigationStrings get navigation => NavigationStrings(_l10n);
  
  /// 云盘下载相关的文本
  CloudDownloadStrings get cloudDownload => CloudDownloadStrings(_l10n);
  
  /// 学堂下载相关的文本
  LearnDownloadStrings get learnDownload => LearnDownloadStrings(_l10n);
  
  /// 设置相关的文本
  SettingsStrings get settings => SettingsStrings(_l10n);
}

/// 应用级别的字符串
class AppStrings {
  final AppLocalizations _l10n;
  AppStrings(this._l10n);
  
  String get title => _l10n.app_title;
}

/// 导航相关的字符串
class NavigationStrings {
  final AppLocalizations _l10n;
  NavigationStrings(this._l10n);
  
  String get cloudDownload => _l10n.navigation_cloudDownload;
  String get learnDownload => _l10n.navigation_learnDownload;
  String get settings => _l10n.navigation_settings;
}

/// 云盘下载相关的字符串
class CloudDownloadStrings {
  final AppLocalizations _l10n;
  CloudDownloadStrings(this._l10n);
  
  String get title => _l10n.cloudDownload_title;
  String get shareLinkLabel => _l10n.cloudDownload_shareLinkLabel;
  String get shareLinkHint => _l10n.cloudDownload_shareLinkHint;
  String get parseLink => _l10n.cloudDownload_parseLink;
  String get parsing => _l10n.cloudDownload_parsing;
  String get enterShareLink => _l10n.cloudDownload_enterShareLink;
  String get validatingLink => _l10n.cloudDownload_validatingLink;
  String get fileList => _l10n.cloudDownload_fileList;
  String get selectAll => _l10n.cloudDownload_selectAll;
  String get deselectAll => _l10n.cloudDownload_deselectAll;
  String get downloadSelected => _l10n.cloudDownload_downloadSelected;
  String get downloading => _l10n.cloudDownload_downloading;
  String get noFiles => _l10n.cloudDownload_noFiles;
  String get linkValidatedGettingTree => _l10n.cloudDownload_linkValidatedGettingTree;
  String parseSuccessCanDownload(int count) => _l10n.cloudDownload_parseSuccessCanDownload(count);
  String parseSuccessPreviewOnly(int count) => _l10n.cloudDownload_parseSuccessPreviewOnly(count);
  String parseFailed(String error) => _l10n.cloudDownload_parseFailed(error);
  String get selectFilesFirst => _l10n.cloudDownload_selectFilesFirst;
  String get parseLinkFirst => _l10n.cloudDownload_parseLinkFirst;
  String get previewOnlyNoDownload => _l10n.cloudDownload_previewOnlyNoDownload;
  String get openingFolderPicker => _l10n.cloudDownload_openingFolderPicker;
  String get selectDownloadDirectory => _l10n.cloudDownload_selectDownloadDirectory;
  String folderPickerFailed(String error) => _l10n.cloudDownload_folderPickerFailed(error);
  String get noDirectorySelected => _l10n.cloudDownload_noDirectorySelected;
  String downloadingTo(String directory) => _l10n.cloudDownload_downloadingTo(directory);
  String get downloadCancelled => _l10n.cloudDownload_downloadCancelled;
  String downloadCompleted(int count, String directory) => _l10n.cloudDownload_downloadCompleted(count, directory);
  String downloadFailed(String error) => _l10n.cloudDownload_downloadFailed(error);
  String get cancelDownload => _l10n.cloudDownload_cancelDownload;
  String get cancellingDownload => _l10n.cloudDownload_cancellingDownload;
  String downloadProgress(String percent) => _l10n.cloudDownload_downloadProgress(percent);
  String selectedFiles(int count, String size) => _l10n.cloudDownload_selectedFiles(count, size);
  String get downloadSelectedFiles => _l10n.cloudDownload_downloadSelectedFiles;
  String downloadSelectedFilesWithCount(int count, String size) => _l10n.cloudDownload_downloadSelectedFilesWithCount(count, size);
}

/// 学堂下载相关的字符串
class LearnDownloadStrings {
  final AppLocalizations _l10n;
  LearnDownloadStrings(this._l10n);
  
  String get title => _l10n.learnDownload_title;
  String get inDevelopment => _l10n.learnDownload_inDevelopment;
}

/// 设置相关的字符串
class SettingsStrings {
  final AppLocalizations _l10n;
  SettingsStrings(this._l10n);
  
  String get title => _l10n.settings_title;
  String get languageSettings => _l10n.settings_languageSettings;
  String get selectLanguage => _l10n.settings_selectLanguage;
} 