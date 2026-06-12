import 'dart:convert';
import 'dart:io';

/// Локальные настройки устройства (COM-порты весов/принтера/VFD).
/// Хранятся в %LOCALAPPDATA%\MagKassa\settings.json — привязаны к машине,
/// а не к аккаунту: на разных кассах разные порты.
class LocalSettings {
  static final LocalSettings _instance = LocalSettings._internal();
  factory LocalSettings() => _instance;
  LocalSettings._internal();

  Map<String, dynamic> _data = {};
  File? _file;

  Future<void> load() async {
    try {
      final base =
          Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
      final dir = Directory('$base\\MagKassa');
      dir.createSync(recursive: true);
      _file = File('${dir.path}\\settings.json');
      if (_file!.existsSync()) {
        _data = jsonDecode(_file!.readAsStringSync()) as Map<String, dynamic>;
      }
    } catch (_) {
      _data = {};
    }
  }

  String? getString(String key) => _data[key] as String?;
  int? getInt(String key) => _data[key] as int?;

  void set(String key, Object? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    try {
      _file?.writeAsStringSync(jsonEncode(_data), flush: true);
    } catch (_) {}
  }
}
