import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonReportHistoryScreen extends StatefulWidget {
  const CommonReportHistoryScreen({super.key});

  @override
  State<CommonReportHistoryScreen> createState() => _CommonReportHistoryScreenState();
}

class _CommonReportHistoryScreenState extends State<CommonReportHistoryScreen> {
  // Mock data for UI presentation
  final List<Map<String, dynamic>> _reportHistory = [
    {
      "id": "REP-001",
      "date": "05/04/2026",
      "className": "IoT Class SE1601",
      "slot": "Slot 3",
      "category": "Hardware Failure",
      "equipment": "OSC-2023-01",
      "status": "Đã xử lý",
      "color": Colors.green
    },
    {
      "id": "REP-002",
      "date": "03/04/2026",
      "className": "Embedded Systems",
      "slot": "Slot 1",
      "category": "Software Issue",
      "equipment": "",
      "status": "Đang xử lý",
      "color": Colors.orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Lịch sử báo cáo', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95), // Orange tint
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _reportHistory.isEmpty
          ? const Center(child: Text("Chưa có bất kỳ báo cáo nào.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
              itemCount: _reportHistory.length,
              itemBuilder: (context, index) {
                final report = _reportHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt_long, color: Color(0xFFF26F21), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(report['id'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: report['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              report['status'],
                              style: TextStyle(color: report['color'], fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Ngày gửi', report['date']),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.class_outlined, 'Lớp', '${report['className']} - ${report['slot']}'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.warning_amber_rounded, 'Sự cố', report['category']),
                      if (report['equipment'] != null && report['equipment'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.qr_code_scanner, 'Thiết bị', report['equipment']),
                      ]
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)))),
      ],
    );
  }
}
