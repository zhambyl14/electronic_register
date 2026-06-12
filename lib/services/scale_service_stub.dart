import 'dart:async';
class ScaleService {
  static final ScaleService _instance = ScaleService._internal();
  factory ScaleService() => _instance;
  ScaleService._internal();
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  Stream<double> get weightStream => _weightController.stream;
  bool get isConnected => false;
  String? get currentPort => null;
  static List<String> getAvailablePorts() => [];
  Future<bool> connect(String portName, {int baudRate = 9600}) async => false;
  Future<void> disconnect() async {}
  void dispose() { _weightController.close(); }
}
