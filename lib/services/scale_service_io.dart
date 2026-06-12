import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class ScaleService {
  static final ScaleService _instance = ScaleService._internal();
  factory ScaleService() => _instance;
  ScaleService._internal();

  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;

  final StreamController<double> _weightController =
      StreamController<double>.broadcast();

  Stream<double> get weightStream => _weightController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentPort;
  String? get currentPort => _currentPort;

  static List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  Future<bool> connect(String portName, {int baudRate = 9600}) async {
    try {
      await disconnect();
      _port = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      if (!_port!.openReadWrite()) {
        _port!.dispose();
        _port = null;
        return false;
      }
      _port!.config = config;
      _currentPort = portName;
      _isConnected = true;

      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
        _onDataReceived,
        onError: (_) => disconnect(),
      );
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    _reader?.close();
    _reader = null;
    if (_port != null && _port!.isOpen) _port!.close();
    _port?.dispose();
    _port = null;
    _isConnected = false;
    _currentPort = null;
  }

  String _buffer = '';

  void _onDataReceived(Uint8List data) {
    try {
      _buffer += String.fromCharCodes(data);
      while (_buffer.contains('\n') || _buffer.contains('\r')) {
        int idx = _buffer.indexOf('\n');
        if (idx == -1) idx = _buffer.indexOf('\r');
        final line = _buffer.substring(0, idx).trim();
        _buffer = _buffer.substring(idx + 1);
        if (line.isNotEmpty) {
          final weight = _parseWeight(line);
          if (weight != null && weight >= 0) {
            _weightController.add(weight);
          }
        }
      }
      if (_buffer.length > 200) _buffer = '';
    } catch (_) {}
  }

  double? _parseWeight(String line) {
    final regExp = RegExp(r'[\+\-]?\s*(\d+\.?\d*)');
    for (final match in regExp.allMatches(line)) {
      final str = match.group(1);
      if (str != null) {
        final value = double.tryParse(str);
        if (value != null && value >= 0 && value < 1000) return value;
      }
    }
    return null;
  }

  void dispose() {
    disconnect();
    _weightController.close();
  }
}
