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
                  ],
                ),
              );
           }).toList(),
      ],
    );
  }
}

