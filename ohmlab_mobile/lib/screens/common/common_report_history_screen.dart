import 'package:flutter/material.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử báo cáo', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: _reportHistory.isEmpty
          ? const Center(child: Text("Chưa có bất kỳ báo cáo nào.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reportHistory.length,
              itemBuilder: (context, index) {
                final report = _reportHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(report['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: report['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: report['color'].withOpacity(0.5)),
                              ),
                              child: Text(
                                report['status'],
                                style: TextStyle(color: report['color'], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.calendar_today, 'Ngày gửi:', report['date']),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.class_, 'Lớp:', '${report['className']} - ${report['slot']}'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.warning_amber_rounded, 'Sự cố:', report['category']),
                        if (report['equipment'] != null && report['equipment'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.developer_board, 'Thiết bị:', report['equipment']),
                        ]
                      ],
                    ),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
      ],
    );
  }
}
