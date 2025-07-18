import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('THUDownloader');
  
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // 在开发环境中打印到控制台
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }
  
  static void info(String message) {
    _logger.info(message);
  }
  
  static void warning(String message) {
    _logger.warning(message);
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
  
  static void debug(String message) {
    _logger.fine(message);
  }
} 