import 'package:flutter/material.dart';
import 'lecturer_propose_schedule_screen.dart';
import 'lecturer_session_management_screen.dart';

class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lecturer Dashboard', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
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
              const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTaskCard(context, 'Grade Lab 3 Reports', 'IoT Class SE1601', const LecturerSessionManagementScreen()),
              const SizedBox(height: 12),
              _buildTaskCard(context, 'Propose Schedule', 'Embedded Systems', const LecturerProposeScheduleScreen()),
              const SizedBox(height: 32),
              const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildActionGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String subtitle, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
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

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(context, 'My Classes', 'View the list of assigned classes', null),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Equipment Check', 'Verify lab tools availability', const LecturerSessionManagementScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Incident Reports', 'Review student incident logs', null),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Timetable', 'View scheduled practicals', null),
      ],
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
