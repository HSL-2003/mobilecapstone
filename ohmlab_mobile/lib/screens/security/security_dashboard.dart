import 'package:flutter/material.dart';
import 'security_room_status_screen.dart';

class SecurityDashboard extends StatelessWidget {
  const SecurityDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Security Dashboard', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lab Status Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatusMetric('In Use', '4', Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusMetric('Available', '12', Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusMetric('Maint.', '1', Colors.orange)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Current Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildRoomCard('Lab 301', 'IoT Practical', 'Locked', Colors.redAccent),
              const SizedBox(height: 12),
              _buildRoomCard('Lab 302', 'Circuit Design', 'In Use', Colors.green),
              const SizedBox(height: 32),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildActionCard(context, 'Update Room Status', 'Manage lab availability state', const SecurityRoomStatusScreen()),
              const SizedBox(height: 12),
              _buildActionCard(context, 'Timetable Viewer', 'Check daily class schedules', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(String room, String session, String status, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(room, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(session, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, Widget? destination) {
    return InkWell(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
