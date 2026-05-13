import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';
import 'lecturer_equipment_history_screen.dart';

class LecturerEquipmentHubScreen extends StatelessWidget {
  const LecturerEquipmentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Equipment Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: Color(0xFF1E1E1E))),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF26F21),
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Scan Equipment'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalEquipmentScanner(),
            LecturerEquipmentHistoryScreen(hideAppBar: true),
          ],
        ),
      ),
    );
  }
}

class _GlobalEquipmentScanner extends StatefulWidget {
  const _GlobalEquipmentScanner();

  @override
  State<_GlobalEquipmentScanner> createState() => _GlobalEquipmentScannerState();
}

class _GlobalEquipmentScannerState extends State<_GlobalEquipmentScanner> {
  final UserService _userService = UserService();
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoadingEquip = true;
  List<dynamic> _equipments = [];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    try {
      final res = await _userService.searchEquipment(
        pageNum: 1,
        pageSize: 100,
        keyword: "",
        status: "",
      );
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            if (res.data is Map && res.data.containsKey('data')) {
              final payloadData = res.data['data'];
              if (payloadData is Map && payloadData.containsKey('pageData')) {
                _equipments = payloadData['pageData'] is List ? payloadData['pageData'] : [];
              } else if (payloadData is List) {
                _equipments = payloadData;
              }
            }
            _isLoadingEquip = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoadingEquip = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingEquip = false; });
    }
  }

  void _simulateScan() {
    if (_equipments.isNotEmpty) {
      final first = _equipments.first;
      final String id = (first['equipmentId'] ?? first['id'])?.toString() ?? '';
      if (id.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating scan for first item...'), duration: Duration(seconds: 1)));
        _fetchAndShowEquipmentById(context, id);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No equipment available to simulate scan.')));
    }
  }

  Future<void> _pickAndScanImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null && mounted) _onQRScanned(context, code);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kh�ng t�m th?y m� QR trong ?nh!'), backgroundColor: Colors.red));
    }
  }

  void _onQRScanned(BuildContext context, String scannedCode) {
    FocusScope.of(context).unfocus();

    // Parse URL để lấy equipmentId từ path cuối cùng
    // Ví dụ: https://swd392be.io.vn/equipment/G8goZ → G8goZ
    String equipmentId = scannedCode.trim();
    try {
      final uri = Uri.parse(scannedCode);
      if (uri.pathSegments.isNotEmpty) {
        equipmentId = uri.pathSegments.last;
      }
    } catch (_) {
      // Nếu không parse được URL, dùng nguyên giá trị scan
    }

    if (equipmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được mã QR!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Gọi API để lấy thông tin thiết bị
    _fetchAndShowEquipmentById(context, equipmentId);
  }

  Future<void> _fetchAndShowEquipmentById(BuildContext context, String equipmentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.getEquipmentById(equipmentId);
      if (context.mounted) Navigator.pop(context);

      if (res.status == 200 || res.status == 201) {
        final payload = res.data;
        Map<String, dynamic>? equip;
        if (payload is Map && payload.containsKey('data')) {
          final d = payload['data'];
          equip = d is Map ? Map<String, dynamic>.from(d) : null;
        } else if (payload is Map) {
          equip = Map<String, dynamic>.from(payload);
        }

        if (equip != null && context.mounted) {
          _showEquipmentDetailDialog(context, equip);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không tìm thấy thiết bị với ID: $equipmentId'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Không thể lấy thông tin thiết bị'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối server'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Scan Equipment QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text('Quét mã QR dán trên thiết bị để xem thông tin và phân bổ cho team.', style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),

        // Camera QR Scanner Box
        if (_isLoadingEquip)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFFF26F21))))
        else
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF26F21).withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(controller: _scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _onQRScanned(context, barcode!.rawValue!);
                    }
                  },
                ),
                // Corner overlays for QR viewfinder
                Positioned.fill(
                  child: CustomPaint(painter: _QRViewfinderPainter()),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      tooltip: 'T?i ?nh QR t? thu vi?n',
                      onPressed: _pickAndScanImage,
                    ),
                  ),
                ),
                Positioned(
                  top: 12, right: 64,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                      tooltip: 'Gi? l?p Qu�t (Test)',
                      onPressed: _simulateScan,
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Center(
                    child: Text('Đưa mã QR vào khung để quét', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        const Text('All Active Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        if (_isLoadingEquip)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF26F21))))
        else if (_equipments.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No issued equipment data.', style: TextStyle(color: Colors.grey))))
        else
           ..._equipments.map((equip) {
              final String equipName = equip['equipmentName'] ?? equip['name'] ?? equip['equipmentCode'] ?? 'Unknown Equipment';
              final String equipCode = equip['equipmentCode']?.toString() ?? '-';
              final String roomId = equip['roomId']?.toString() ?? equip['roomName']?.toString() ?? 'N/A';
              final String equipStatus = equip['equipmentStatus']?.toString() ?? equip['status']?.toString() ?? 'N/A';
              final String equipTypeName = equip['equipmentTypeName']?.toString() ?? '';
              final String? qrBase64 = equip['equipmentQr']?.toString();

              Color statusColor = Colors.grey;
              if (equipStatus.toLowerCase() == 'available') statusColor = Colors.green;
              if (equipStatus.toLowerCase() == 'in use' || equipStatus.toLowerCase() == 'inuse') statusColor = Colors.orange;
              if (equipStatus.toLowerCase() == 'broken') statusColor = Colors.red;

              return GestureDetector(
                onTap: () { final String rawId = (equip['equipmentId'] ?? equip['id'])?.toString() ?? ''; if (rawId.isNotEmpty) _fetchAndShowEquipmentById(context, rawId); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: qrBase64 != null ? const Color(0xFFFFF3E0) : Colors.grey[100]!,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.build, color: Color(0xFFF26F21), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(equipName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E1E1E))),
                            const SizedBox(height: 2),
                            Text('Code: $equipCode', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Room ID: $roomId  |  $equipTypeName', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(equipStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                          const SizedBox(height: 6),
                          IconButton(
                            icon: const Icon(Icons.handshake_outlined, color: Color(0xFFF26F21)),
                            tooltip: 'Mượn cho Team',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final String rawId = (equip['id'] ?? equip['equipmentId'])?.toString() ?? '';
                              if (rawId.isNotEmpty) {
                                _showBorrowBottomSheet(context, rawId, equipName);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thiết bị không hợp lệ (Mất ID).')));
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
           }).toList(),

      ],
    );
  }

  void _showEquipmentDetailDialog(BuildContext context, Map<String, dynamic> equip) {
    final String equipId = (equip['equipmentId'] ?? equip['id'] ?? '-').toString();
    final String equipName = equip['equipmentName'] ?? equip['name'] ?? 'Unknown';
    final String equipCode = equip['equipmentCode']?.toString() ?? '-';
    final String serial = equip['equipmentNumberSerial']?.toString() ?? '-';
    final String roomId = equip['roomId']?.toString() ?? equip['roomName']?.toString() ?? 'N/A';

    final String equipStatus = equip['equipmentStatus']?.toString() ?? equip['status']?.toString() ?? 'N/A';
    final String equipTypeName = equip['equipmentTypeName']?.toString() ?? '';
    final String desc = equip['equipmentDescription']?.toString() ?? '';
    final String? qrBase64 = equip['equipmentQr']?.toString();
    final String? typeImgUrl = equip['equipmentTypeUrlImg']?.toString();

    Color statusColor = Colors.grey;
    if (equipStatus.toLowerCase() == 'available') statusColor = Colors.green;
    if (equipStatus.toLowerCase() == 'in use' || equipStatus.toLowerCase() == 'inuse') statusColor = Colors.orange;
    if (equipStatus.toLowerCase() == 'broken') statusColor = Colors.red;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (typeImgUrl != null && typeImgUrl.isNotEmpty && typeImgUrl != 'string')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(typeImgUrl, width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.build, size: 48, color: Color(0xFFF26F21))),
                    )
                  else
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.build, size: 36, color: Color(0xFFF26F21)),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E1E1E))),
                        const SizedBox(height: 4),
                        Text(equipTypeName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(equipStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.fingerprint, 'Equipment ID', equipId),
              _buildDetailRow(Icons.qr_code, 'Equipment Code', equipCode),
              _buildDetailRow(Icons.tag, 'Serial Number', serial),
              _buildDetailRow(Icons.meeting_room, 'Room ID', roomId),

              if (desc.isNotEmpty && desc != 'string') _buildDetailRow(Icons.info_outline, 'Description', desc),
              if (qrBase64 != null && qrBase64.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Equipment QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E1E))),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Builder(
                      builder: (_) {
                        try {
                          final bytes = base64Decode(qrBase64);
                          return Image.memory(bytes, width: 200, height: 200, fit: BoxFit.contain);
                        } catch (_) {
                          return const Text('QR code unavailable', style: TextStyle(color: Colors.grey));
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final String rawId = (equip['id'] ?? equip['equipmentId'])?.toString() ?? '';
                    if (rawId.isNotEmpty) {
                      _showBorrowBottomSheet(context, rawId, equipName);
                    }
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Borrow for Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  void _showBorrowBottomSheet(BuildContext context, String equipmentId, String equipmentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BorrowEquipmentForm(equipmentId: equipmentId, equipmentName: equipmentName),
    );
  }
}

class _BorrowEquipmentForm extends StatefulWidget {
  final String equipmentId;
  final String equipmentName;

  const _BorrowEquipmentForm({required this.equipmentId, required this.equipmentName});

  @override
  State<_BorrowEquipmentForm> createState() => _BorrowEquipmentFormState();
}

class _BorrowEquipmentFormState extends State<_BorrowEquipmentForm> {
  final UserService _userService = UserService();
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  
  final _teamIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Default the name field
    _nameController.text = 'Mượn ' + widget.equipmentName;
  }

  Future<void> _submit() async {
    final teamIdText = _teamIdController.text.trim();
    final nameText = _nameController.text.trim();
    
    if (teamIdText.isEmpty || nameText.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Team ID và Tên thiết bị!')));
      return;
    }

    final int? tId = int.tryParse(teamIdText);
    if (tId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team ID phải là số hợp lệ!')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final payload = {
        "teamId": tId,
        "equipmentId": widget.equipmentId,
        "teamEquipmentName": nameText,
        "teamEquipmentDescription": _descController.text.trim(),
      };

      final res = await _userService.borrowEquipment(payload);
      
      setState(() => _isSaving = false);
      
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phân bổ thiết bị cho Team thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.message ?? "Không thể mượn thiết bị."}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server connection error.'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bổ thiết bị: ${widget.equipmentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 24),
            _buildField('Tên Thiết Bị (Cho Team) *', _nameController),
            _buildField('Team ID *', _teamIdController, isNumber: true),
            _buildField('Mô tả thêm', _descController, maxLines: 2),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF26F21),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300]
                ),
                child: _isSaving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Phân bổ thiết bị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for QR scanner viewfinder corners
class _QRViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerSize = 24.0;
    const strokeWidth = 3.0;
    final paint = Paint()
      ..color = const Color(0xFFF26F21)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Semi-dark overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Center clear area
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final boxSize = size.width * 0.55;
    final left = centerX - boxSize / 2;
    final top = centerY - boxSize / 2;
    final right = centerX + boxSize / 2;
    final bottom = centerY + boxSize / 2;

    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()..color = Colors.transparent..blendMode = BlendMode.clear,
    );

    // Corners
    // Top-left
    canvas.drawLine(Offset(left, top + cornerSize), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerSize, top), paint);
    // Top-right
    canvas.drawLine(Offset(right - cornerSize, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerSize), paint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerSize), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerSize, bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerSize, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
