import 'dart:developer' as developer;

class CloudDownloadLogger {
  static const String _tag = 'CloudDownload';

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // INFO level
    );
  }

  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 700, // DEBUG level
    );
  }

  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // WARNING level
    );
  }

  static void error(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // ERROR level
      error: error,
    );
  }

  // 专门用于文件选择相关的日志
  static void selection(String message) {
    info(message, tag: '${_tag}_Selection');
  }

  // 专门用于下载相关的日志
  static void download(String message) {
    info(message, tag: '${_tag}_Download');
  }

  // 专门用于网络请求相关的日志
  static void network(String message) {
    info(message, tag: '${_tag}_Network');
  }
} 