import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LecturerEquipmentHistoryScreen extends StatefulWidget {
  const LecturerEquipmentHistoryScreen({super.key});

  @override
  State<LecturerEquipmentHistoryScreen> createState() => _LecturerEquipmentHistoryScreenState();
}

class _LecturerEquipmentHistoryScreenState extends State<LecturerEquipmentHistoryScreen> {
  // Mock data for UI presentation
  final List<Map<String, dynamic>> _equipmentHistory = [
    {
      "date": "05/04/2026",
      "team": "Team 1",
      "class": "IoT Class SE1601",
      "equipment": "Oscilloscope OSC-2023-01",
      "borrowTime": "07:30 AM",
      "returnTime": "09:45 AM",
      "status": "Đã trả",
      "statusColor": Colors.green,
    },
    {
      "date": "06/04/2026",
      "team": "Team 2",
      "class": "Embedded Systems",
      "equipment": "Function Generator FG-102",
      "borrowTime": "13:00 PM",
      "returnTime": null,
      "status": "Đang mượn",
      "statusColor": Colors.orange,
    },
    {
      "date": "02/04/2026",
      "team": "Team 1",
      "class": "IoT Class SE1601",
      "equipment": "Breadboards x5",
      "borrowTime": "07:30 AM",
      "returnTime": "09:50 AM",
      "status": "Trả muộn",
      "statusColor": Colors.red,
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
              title: const Text('Lịch sử thiết bị', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _equipmentHistory.isEmpty
          ? const Center(child: Text("Chưa có lịch sử mượn trả thiết bị.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
              itemCount: _equipmentHistory.length,
              itemBuilder: (context, index) {
                final hist = _equipmentHistory[index];
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
                                child: const Icon(Icons.handyman, color: Color(0xFFF26F21), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(hist['date'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: hist['statusColor'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              hist['status'],
                              style: TextStyle(color: hist['statusColor'], fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.group_outlined, 'Lớp / Nhóm', '${hist['class']} - ${hist['team']}'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.developer_board, 'Thiết bị', hist['equipment']),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeBadge(Icons.call_made, 'Mượn: ${hist['borrowTime']}', Colors.blue),
                            if (hist['returnTime'] != null)
                              _buildTimeBadge(Icons.call_received, 'Trả: ${hist['returnTime']}', Colors.green)
                            else
                              _buildTimeBadge(Icons.timer, 'Chưa trả', Colors.orange),
                          ],
                        ),
                      )
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

  Widget _buildTimeBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
