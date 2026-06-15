import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Level _level = kReleaseMode ? Level.warning : Level.debug;

  static final Logger instance = Logger(
    level: _level,
    printer: SimplePrinter(printTime: true, colors: false),
  );
}
