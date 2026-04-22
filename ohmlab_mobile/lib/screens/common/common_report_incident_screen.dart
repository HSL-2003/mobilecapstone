import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';

class CommonReportIncidentScreen extends StatefulWidget {
  final bool hideAppBar;
  const CommonReportIncidentScreen({super.key, this.hideAppBar = false});

  @override
  State<CommonReportIncidentScreen> createState() => _CommonReportIncidentScreenState();
}

class _CommonReportIncidentScreenState extends State<CommonReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ReportService _reportService = ReportService();

  String _selectedCategory = 'Hardware Failure';

  List<dynamic> _todaySlots = [];
  String? _selectedSlotName;
  bool _isLoadingSlots = true;

  List<dynamic> _todayClasses = [];
  String? _selectedClassId;
  bool _isLoadingClasses = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      final res = await _reportService.getTodaySlots();
      if (res.status == 200 || res.status == 201) {
        final dataWrapper = res.data;
        if (dataWrapper is Map && dataWrapper.containsKey('data')) {
          final slots = dataWrapper['data']['slots'] ?? [];
          if (mounted) {
            setState(() {
              _todaySlots = slots is List ? slots : [slots];
              _isLoadingSlots = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingSlots = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _fetchClasses(String slotName) async {
    setState(() {
      _isLoadingClasses = true;
      _selectedClassId = null;
      _todayClasses = [];
    });
    try {
      final res = await _reportService.getTodayClasses(slotName);
      if (res.status == 200 || res.status == 201) {
        final payload = res.data;
        if (mounted) {
          setState(() {
            if (payload is Map && payload.containsKey('data')) {
              final items = payload['data'];
              if (items is List) _todayClasses = items;
              else if (items != null) _todayClasses = [items];
            } else if (payload is List) {
              _todayClasses = payload;
            }
            _isLoadingClasses = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingClasses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.hideAppBar ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Báo cáo sự cố', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF26F21), Color(0xFFFFA726)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Ghi nhận Sự cố', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0)),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                     child: const Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Icon(Icons.info_outline, color: Colors.white, size: 20),
                         SizedBox(width: 8),
                         Expanded(child: Text('Vui lòng chọn ca học và lớp học hôm nay của bạn trước khi điền thông tin chi tiết sự cố.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500))),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Slot Selection
                      const Text('Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (_isLoadingSlots)
                        const LinearProgressIndicator(color: Color(0xFFF26F21))
                      else if (_todaySlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(child: Text('Bạn không có slot nào trong ngày hôm nay nên không thể tạo báo cáo sự cố .', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        )
                      else
                        _buildDropdown(
                          value: _selectedSlotName,
                          hint: 'Chọn Slot',
                          items: _todaySlots.map((slot) {
                            final name = slot['slotName'] ?? slot['name'] ?? slot.toString();
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSlotName = val);
                            if (val != null) _fetchClasses(val);
                          },
                        ),
                      const SizedBox(height: 20),
                      
                      // 2. Class Selection
                      const Text('Lớp Học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (_isLoadingClasses)
                        const LinearProgressIndicator(color: Color(0xFFF26F21))
                      else
                        _buildDropdown(
                          value: _selectedClassId,
                          hint: _selectedSlotName == null ? 'Vui lòng chọn Slot trước' : 'Chọn Lớp học',
                          items: _todayClasses.map((c) {
                            final id = c['id']?.toString() ?? c['classId']?.toString() ?? c['className']?.toString() ?? c['name']?.toString() ?? c.toString();
                            final name = c['className'] ?? c['name'] ?? c['classCode'] ?? 'Unknown Class';
                            final room = c['roomName'] ?? c['room'] ?? '';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text('$name ${room.isNotEmpty ? '($room)' : ''}'),
                            );
                          }).toList(),
                          onChanged: _selectedSlotName == null ? null : (val) => setState(() => _selectedClassId = val),
                        ),
                      
                      if (_selectedSlotName == null || _selectedClassId == null)
                         Padding(
                           padding: const EdgeInsets.only(top: 16),
                           child: Text("Cần chọn Slot và Lớp học để tiếp tục báo cáo.", style: TextStyle(color: Colors.red[300], fontSize: 12, fontStyle: FontStyle.italic)),
                         ),
                         
                      const SizedBox(height: 32),
                      const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 20),

                      // 3. Form fields (Only active if slot & class selected)
                      const Text('Loại Sự cố', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedCategory,
                        hint: 'Loại sự cố',
                        items: const [
                          DropdownMenuItem(value: 'Hardware Failure', child: Text('Hỏng phần cứng (Hardware)')),
                          DropdownMenuItem(value: 'Tool Missing', child: Text('Mất dụng cụ/thiết bị')),
                          DropdownMenuItem(value: 'Software Issue', child: Text('Lỗi phần mềm')),
                          DropdownMenuItem(value: 'Safety Hazard', child: Text('Nguy hiểm/Hỏa hoạn')),
                        ],
                        onChanged: (_selectedSlotName == null || _selectedClassId == null) 
                            ? null 
                            : (val) => setState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: 20),

                      const Text('Mã thiết bị (Tùy chọn)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _equipmentController,
                        enabled: _selectedSlotName != null && _selectedClassId != null,
                        decoration: InputDecoration(
                          hintText: 'VD: OSC-2023-01',
                          filled: true,
                          fillColor: Colors.grey[50], // Soft fill
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                          prefixIcon: const Icon(Icons.qr_code, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Mô tả chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: _selectedSlotName != null && _selectedClassId != null,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Mô tả chuyện gì đã xảy ra hoặc cái gì bị hỏng...',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                        ),
                        validator: (value) {
                           if (_selectedSlotName == null || _selectedClassId == null) return null; // handled by button
                           if (value == null || value.trim().isEmpty) return 'Vui lòng nhập mô tả sự cố';
                           return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: (_selectedSlotName == null || _selectedClassId == null) 
                            ? null 
                            : const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                          color: (_selectedSlotName == null || _selectedClassId == null) ? Colors.grey[300] : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: (_selectedSlotName == null || _selectedClassId == null) 
                            ? [] 
                            : [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (_selectedSlotName == null || _selectedClassId == null) ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
                                );

                                final String title = 'Sự cố: $_selectedCategory';
                                final String eq = _equipmentController.text.trim();
                                final String desc = eq.isNotEmpty 
                                    ? 'Thiết bị: $eq\nChi tiết: ${_descriptionController.text.trim()}' 
                                    : _descriptionController.text.trim();

                                try {
                                  final response = await _reportService.createReport(
                                    title: title,
                                    description: desc,
                                    slot: _selectedSlotName!,
                                    className: _selectedClassId!,
                                  );
                                  
                                  Navigator.pop(context);

                                  if (response.status == 200 || response.status == 201) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Báo cáo sự cố thành công!'), backgroundColor: Colors.green),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(response.message ?? 'Có lỗi xảy ra khi tạo báo cáo.'), backgroundColor: Colors.red),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lỗi kết nối máy chủ!'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Center(
                              child: Text('GỬI BÁO CÁO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value, 
    required String hint, 
    required List<DropdownMenuItem<String>> items, 
    required void Function(String?)? onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: onChanged == null ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          items: items,
          onChanged: onChanged,
          disabledHint: Text(hint, style: TextStyle(color: Colors.grey[400])),
        ),
      ),
    );
  }
}
