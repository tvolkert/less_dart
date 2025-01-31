library logger.less;

import 'dart:async';

// The amount of logging to the console (stderr).
///
const int logLevelDebug = 4; // Debug, Info, Warns and Errors
///
const int logLevelInfo  = 3; // Info, Warns and Errors
///
const int logLevelWarn  = 2; // Warns and Errors - DEFAULT
///
const int logLevelError = 1; // Errors
///
const int logLevelNone  = 0; // None

///
class Logger {
  ///
  static Map<int, Logger> cache = <int, Logger>{};
  ///
  StringBuffer            capture;
  ///
  int                     logLevel;
  ///
  StringBuffer            stderr;

  /*
   * If not runZoned, #id == null. Example:
   * runZoned((){...
   *   StringBuffer b = new StringBuffer();
   *   Logger logger = new Logger(b);
   * },
   * zoneValues: {#id: new Random().nextInt(10000)});
   */
  ///
  factory Logger([StringBuffer buffer]) {
    final int id = Zone.current[#id] ?? -1;

    if (buffer != null && cache[id] != null) {
      throw new StateError('Console buffer yet initialized');
    }

    cache[id] ??= new Logger._(buffer);
    return cache[id];
  }

  ///
  Logger._(this.stderr) {
    stderr ??= new StringBuffer();
    logLevel = logLevelWarn;
  }

  /// remove cache for this id
  void reset() {
    final int id = Zone.current[#id];
    cache[id] = null;
  }

  ///
  /// route the messages to capture buffer
  ///
  void captureStart() {
    capture = new StringBuffer();
  }

  ///
  /// Returns captured messages and goes to normal log mode
  ///
  String captureStop() {
    final String result = capture.toString();
    capture = null;
    return result;
  }

  ///
  void log(String msg) {
    final StringBuffer buffer = (capture == null) ? stderr : capture;

    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write('$msg');
  }

  ///
  void error(String msg) {
    if (logLevel >= logLevelError) log(msg);
  }

  ///
  void warn(String msg) {
    if (logLevel >= logLevelWarn) log(msg);
  }

  ///
  void info(String msg) {
    if (logLevel >= logLevelInfo) log(msg);
  }

  ///
  void debug(String msg) {
    if (logLevel >= logLevelDebug) log(msg);
  }

  ///
  void setLogLevel(int logLevel) {
    this.logLevel = logLevel;
    //cacheLogLevel[id] = logLevel;
  }

  /// Sets the log level to silence
  void silence() {
    setLogLevel(logLevelNone);
  }

  /// Sets the log level to verbose
  void verbose() {
    setLogLevel(logLevelInfo);
  }
}
