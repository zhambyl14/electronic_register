import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_settings.dart';
import '../services/scale_service.dart';
import '../services/printer_service.dart';
import '../services/customer_display_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipNameController = TextEditingController();
  final _shopNameController = TextEditingController(text: 'МОЙ МАГАЗИН');
  final _addressController = TextEditingController();
  final _shopBinController = TextEditingController();
  final _cashierNameController = TextEditingController();

  List<String> _availablePorts = [];
  bool _isSaving = false;
  AuthProvider? _authListenable;

  String? _autoFilledCashierName;
  String? _autoFilledShopName;
  String? _autoFilledIpName;
  String? _autoFilledAddress;

  List<Printer> _printers = [];
  String? _selectedPrinterName;
  String? _selectedRawPort;
  String? _selectedVfdPort;
  String _vfdProtocol = 'epson';
  int _vfdBaud = 9600;

  @override
  void initState() {
    super.initState();
    _ipNameController.text = PrinterService().ipName;
    _shopNameController.text = PrinterService().shopName;
    _addressController.text = PrinterService().address;
    _selectedRawPort = PrinterService().rawPrinterPort;
    _loadPorts();
    _loadPrinters();
    // Восстанавливаем сохранённые порты (только если порт есть на машине,
    // иначе dropdown упадёт на value, которого нет в items)
    final savedVfdPort = LocalSettings().getString('vfdPort');
    if (savedVfdPort != null && _availablePorts.contains(savedVfdPort)) {
      _selectedVfdPort = savedVfdPort;
    }
    _vfdProtocol = LocalSettings().getString('vfdProtocol') ?? 'epson';
    _vfdBaud = LocalSettings().getInt('vfdBaud') ?? 9600;
    if (_selectedRawPort != null &&
        !_availablePorts.contains(_selectedRawPort)) {
      _selectedRawPort = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authListenable = context.read<AuthProvider>();
      _applyAuthData();
      _authListenable!.addListener(_applyAuthData);
    });
  }

  void _applyAuthData() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.uid == null) return;
    final cur = _cashierNameController.text;
    if (cur.isEmpty || cur == _autoFilledCashierName) {
      _autoFilledCashierName = auth.displayName;
      _cashierNameController.text = auth.displayName;
    }
    final shop = _shopNameController.text;
    if (shop.isEmpty || shop == 'МОЙ МАГАЗИН' || shop == _autoFilledShopName) {
      _autoFilledShopName = auth.storeName;
      _shopNameController.text = auth.storeName;
    }
    final ip = _ipNameController.text;
    if (ip.isEmpty || ip == _autoFilledIpName) {
      _autoFilledIpName = auth.ipName;
      _ipNameController.text = auth.ipName;
    }
    final addr = _addressController.text;
    if (addr.isEmpty || addr == _autoFilledAddress) {
      _autoFilledAddress = auth.address;
      _addressController.text = auth.address;
    }
  }

  void _loadPorts() {
    setState(() {
      _availablePorts = ScaleService.getAvailablePorts();
    });
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await PrinterService().getAvailablePrinters();
      setState(() => _printers = printers);
    } catch (_) {}
  }

  @override
  void dispose() {
    _authListenable?.removeListener(_applyAuthData);
    _ipNameController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _shopBinController.dispose();
    _cashierNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Информация о магазине',
                  Icons.store_outlined,
                  children: [
                    _buildField(
                      label: 'ИП / Наименование ИП (шапка чека)',
                      controller: _ipNameController,
                      hint: 'ИП Иванов Иван Иванович',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Название магазина (отображается в чеке)',
                      controller: _shopNameController,
                      hint: 'МОЙ МАГАЗИН',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Адрес магазина',
                      controller: _addressController,
                      hint: 'г. Алматы, ул. Абая, 1',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Имя кассира (отображается в чеке)',
                      controller: _cashierNameController,
                      hint: 'Кассир',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'БИН (необязательно)',
                      controller: _shopBinController,
                      hint: '123456789012',
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveShopInfo,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Сохранить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  'Настройки принтера',
                  Icons.print_outlined,
                  children: [
                    _buildDropdownField<String>(
                      label: 'Выбор Windows-принтера (PDF)',
                      hint: 'Выберите принтер',
                      value: _selectedPrinterName,
                      items: _printers
                          .map((p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(p.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedPrinterName = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField<String>(
                      label: 'COM-порт термопринтера (ESC/POS, необязательно)',
                      hint: 'Без прямой печати',
                      value: _selectedRawPort,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Без прямой печати'),
                        ),
                        ..._availablePorts.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedRawPort = val);
                        PrinterService().setRawPrinterPort(val);
                        LocalSettings().set('rawPrinterPort', val);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'При указании COM-порта чеки отправляются напрямую (CP866 ESC/POS).\n'
                      'Без COM-порта — через Windows-принтер (PDF).',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadPrinters,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Обновить список принтеров'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  'Экран покупателя (VFD)',
                  Icons.monitor_outlined,
                  children: [
                    const Text(
                      'Выберите COM-порт VFD-дисплея (2-строчный экран покупателя). '
                      'Подключите дисплей по USB — он появится в списке портов.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField<String>(
                      label: 'COM-порт VFD-дисплея',
                      hint: 'Не используется',
                      value: _selectedVfdPort,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Не используется'),
                        ),
                        ..._availablePorts.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedVfdPort = val);
                        CustomerDisplayService().setVfdPort(val);
                        LocalSettings().set('vfdPort', val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Протокол дисплея',
                            hint: 'Epson ESC/POS',
                            value: _vfdProtocol,
                            items: const [
                              DropdownMenuItem(
                                value: 'epson',
                                child: Text(
                                    'Epson ESC/POS (2 строки, кириллица)'),
                              ),
                              DropdownMenuItem(
                                value: 'cd5220',
                                child: Text('CD5220 / DSP-800 (2 строки)'),
                              ),
                              DropdownMenuItem(
                                value: 'aedex',
                                child: Text('AEDEX (1-2 строки, латиница)'),
                              ),
                              DropdownMenuItem(
                                value: 'plain',
                                child: Text('Числовое табло (только сумма)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _vfdProtocol = val);
                              CustomerDisplayService().setVfdProtocol(val);
                              LocalSettings().set('vfdProtocol', val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 130,
                          child: _buildDropdownField<int>(
                            label: 'Скорость',
                            hint: '9600',
                            value: _vfdBaud,
                            items: [1200, 2400, 4800, 9600, 19200]
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b.toString()),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _vfdBaud = val);
                              CustomerDisplayService().setVfdBaud(val);
                              LocalSettings().set('vfdBaud', val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'При выборе порта корзина будет автоматически отображаться '
                      'на дисплее покупателя в реальном времени.\n'
                      'Если на дисплее ничего не видно — переключайте протокол, '
                      'пока не появится текст: разные модели понимают разные '
                      'команды.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  'Информация о системе',
                  Icons.info_outline,
                  children: [
                    _infoRow('Приложение', 'iMag Kassa v1.0'),
                    const SizedBox(height: 8),
                    const Text(
                      'Данные хранятся в облаке и изолированы по пользователю.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: const Row(
        children: [
          Text(
            'Настройки',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon,
      {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value, // ignore: deprecated_member_use
          hint: Text(hint,
              style: const TextStyle(fontSize: 13)),
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(isDense: true),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF1A2332))),
        ],
      ),
    );
  }

  Future<void> _saveShopInfo() async {
    setState(() => _isSaving = true);
    try {
      final ipName = _ipNameController.text.trim();
      final shopName = _shopNameController.text.trim();
      final address = _addressController.text.trim();
      final cashierName = _cashierNameController.text.trim();
      final bin = _shopBinController.text.trim();

      // Обновить PrinterService (локально)
      PrinterService().setShopInfo(
        name: shopName,
        bin: bin,
        ipName: ipName,
        address: address,
      );
      CustomerDisplayService().setShopName(shopName);

      // Сохранить профиль в Firestore
      if (mounted) {
        await context.read<AuthProvider>().saveProfile(
          displayName: cashierName,
          storeName: shopName,
          ipName: ipName,
          address: address,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные магазина сохранены!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

}
