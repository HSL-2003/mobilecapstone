import 'package:flutter/material.dart';
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
  final TextEditingController _qrController = TextEditingController();
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  
  bool _isLoadingEquip = true;
  List<dynamic> _equipments = [];

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

  Future<void> _verifyQR() async {
    final qr = _qrController.text.trim();
    if (qr.isEmpty) return;
    
    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      // Dùng "0" cho ID mặc định khi không nằm trong class cụ thể
      final res = await _reportService.verifyEquipmentQR("0", qr);
      Navigator.pop(context);
      
      if (res.status == 200 || res.status == 201) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận mã thiết bị hợp lệ!'), backgroundColor: Colors.green));
         _qrController.clear();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Mã QR không hợp lệ'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối kiểm tra mã QR'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Global Equipment Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhập hoặc quét mã thiết bị bất kỳ để tìm kiếm thông tin nhanh.', style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrController,
                      decoration: InputDecoration(
                        hintText: 'Mã QR (VD: OSC-01)',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                        prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFFF26F21)),
                      ),
                      onFieldSubmitted: (_) => _verifyQR(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _verifyQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Kiểm tra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
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
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Không có dữ liệu thiết bị cấp phát.', style: TextStyle(color: Colors.grey))))
        else
           ..._equipments.map((equip) {
              final name = equip['equipmentName'] ?? equip['name'] ?? equip['equipmentCode'] ?? 'Unknown Equipment';
              final qty = equip['quantity'] ?? 1;
              final desc = equip['description'] ?? '';
              final title = desc.isNotEmpty ? '$name ($desc)' : name;
              final status = equip['status']?.toString() ?? '';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.build, color: Color(0xFFF26F21), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('$title x$qty', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E1E1E))),
                            if (status.isNotEmpty) 
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Status: $status', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.handshake_outlined, color: Color(0xFFF26F21)),
                        tooltip: 'Mượn cho Team',
                        onPressed: () {
                          final String rawId = (equip['id'] ?? equip['equipmentId'])?.toString() ?? '';
                          final String name = equip['name'] ?? equip['equipmentName'] ?? equip['equipmentCode'] ?? '';
                          if (rawId.isNotEmpty) {
                            _showBorrowBottomSheet(context, rawId, name);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thiết bị không hợp lệ (Mất ID).')));
                          }
                        },
                      ),
                    ],
                  ),
                );
           }).toList(),
      ],
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
  
  final _teamIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isSaving = false;

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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${res.message ?? "Không thể mượn thiết bị."}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối máy chủ.'), backgroundColor: Colors.red));
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
