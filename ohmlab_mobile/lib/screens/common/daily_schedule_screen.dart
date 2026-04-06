import 'package:flutter/material.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';

class DailyScheduleScreen extends StatefulWidget {
  const DailyScheduleScreen({super.key});

  @override
  State<DailyScheduleScreen> createState() => _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends State<DailyScheduleScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  String? _errorMessage;
  
  List<dynamic> _slots = [];
  int _totalCount = 0;
  String _todayDate = '';
  List<dynamic> _warnings = [];

  @override
  void initState() {
    super.initState();
    _fetchTodaySlots();
  }

  Future<void> _fetchTodaySlots() async {
    try {
      final response = await _reportService.getTodaySlots();
      if (response.status == 200 || response.status == 201) {
        final dataWrapper = response.data;
        if (dataWrapper is Map && dataWrapper.containsKey('data')) {
          final payload = dataWrapper['data'];
          if (mounted) {
            setState(() {
              if (payload is Map) {
                _slots = payload['slots'] ?? [];
                _totalCount = payload['totalCount'] ?? 0;
                _todayDate = payload['today'] ?? 'Hôm nay';
                _warnings = payload['warnings'] ?? [];
              } else if (payload is List) {
                _slots = payload;
              }
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() { _errorMessage = 'Không thể tải báo cáo hôm nay.'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Lỗi kết nối máy chủ.'; _isLoading = false; });
    }
  }

  void _showSlotClassesBottomSheet(String slotName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SlotClassesBottomSheet(slotName: slotName, reportService: _reportService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Lịch trình hôm nay', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
                onRefresh: _fetchTodaySlots,
                color: const Color(0xFFF26F21),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Stats
                      _buildHeaderStats(),
                      const SizedBox(height: 24),
                      
                      // Warnings Section (if any)
                      if (_warnings.isNotEmpty) ...[
                        const Text('Cảnh báo hệ thống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        ..._warnings.map((w) => _buildWarningCard(w.toString())).toList(),
                        const SizedBox(height: 24),
                      ],

                      // Slots Section
                      const Text('Danh sách Slot (Ca học)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      if (_slots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                          child: const Text('Hôm nay không có ca học nào được xếp hành.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _slots.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final slot = _slots[index];
                            final slotName = slot['slotName'] ?? slot['name'] ?? slot.toString();
                            // Optional: If API returns more info in the slot item, display it.
                            return _buildSlotCard(slotName);
                          },
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF26F21),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ngày $_todayDate', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_totalCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -2.0)),
              const SizedBox(width: 8),
              const Text('lớp học hôm nay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.red[800], fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSlotCard(String slotName) {
    return InkWell(
      onTap: () => _showSlotClassesBottomSheet(slotName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(slotName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _SlotClassesBottomSheet extends StatefulWidget {
  final String slotName;
  final ReportService reportService;

  const _SlotClassesBottomSheet({required this.slotName, required this.reportService});

  @override
  State<_SlotClassesBottomSheet> createState() => _SlotClassesBottomSheetState();
}

class _SlotClassesBottomSheetState extends State<_SlotClassesBottomSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await widget.reportService.getTodayClasses(widget.slotName);
      if (response.status == 200 || response.status == 201) {
        final payload = response.data;
        if (mounted) {
          setState(() {
            if (payload is Map && payload.containsKey('data')) {
               final items = payload['data'];
               if (items is List) _classes = items;
               else if (items != null) _classes = [items];
            } else if (payload is List) {
               _classes = payload;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _errorMessage = 'Không tải được danh sách lớp.'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Lỗi kết nối máy chủ.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Các lớp trong ${widget.slotName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[500],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _classes.isEmpty
                        ? Center(child: Text('Không có lớp nào trong ${widget.slotName}.', style: TextStyle(color: Colors.grey[500])))
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _classes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final clazz = _classes[index];
                              // Tùy chỉnh field name dựa theo API thật
                              final className = clazz['className'] ?? clazz['name'] ?? clazz['classCode'] ?? 'Unknown Class';
                              final subject = clazz['subjectCode'] ?? clazz['subjectName'] ?? clazz['subject'] ?? 'No Subject';
                              final lecturer = clazz['lecturerName'] ?? clazz['lecturer'] ?? 'No Lecturer';
                              final room = clazz['roomName'] ?? clazz['room'] ?? 'Unknown Room';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFF26F21).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                          child: Text(room, style: const TextStyle(color: Color(0xFFF26F21), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(subject, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Text(lecturer, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }
}
