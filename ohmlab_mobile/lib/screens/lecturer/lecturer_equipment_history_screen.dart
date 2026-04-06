import 'package:flutter/material.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử Mượn/Trả thiết bị', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: _equipmentHistory.isEmpty
          ? const Center(child: Text("Chưa có lịch sử mượn trả thiết bị.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _equipmentHistory.length,
              itemBuilder: (context, index) {
                final hist = _equipmentHistory[index];
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
                            Text('${hist['date']} - ${hist['team']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: hist['statusColor'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: hist['statusColor'].withOpacity(0.5)),
                              ),
                              child: Text(
                                hist['status'],
                                style: TextStyle(color: hist['statusColor'], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.class_, 'Lớp:', hist['class']),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.developer_board, 'Thiết bị:', hist['equipment']),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeBadge(Icons.call_made, 'Mượn: ${hist['borrowTime']}', Colors.blue),
                            if (hist['returnTime'] != null)
                              _buildTimeBadge(Icons.call_received, 'Trả: ${hist['returnTime']}', Colors.green)
                            else
                              _buildTimeBadge(Icons.timer, 'Chưa trả', Colors.orange),
                          ],
                        )
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

  Widget _buildTimeBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
