import 'dart:io';

/// Общий лог запуска: %LOCALAPPDATA%\MagKassa\startup.log.
/// Пишется синхронно с flush, чтобы при нативном краше последняя
/// строка указывала на упавший шаг.
File? _logFile;

void initAppLog() {
  try {
    final base =
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    final dir = Directory('$base\\MagKassa');
    dir.createSync(recursive: true);
    _logFile = File('${dir.path}\\startup.log');
  } catch (_) {}
}

void appLog(String msg) {
  try {
    _logFile?.writeAsStringSync(
      '${DateTime.now().toIso8601String()}  $msg\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}
