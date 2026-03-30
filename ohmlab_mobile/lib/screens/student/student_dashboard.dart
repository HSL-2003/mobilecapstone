import 'package:flutter/material.dart';
import 'student_schedule_screen.dart';
import 'student_report_incident_screen.dart';
import 'student_lab_instructions_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
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
              const Text('Upcoming Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildSessionCard(),
              const SizedBox(height: 32),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildActionGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY • 14:00 PM', style: TextStyle(color: Color(0xFFF26F21), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Circuit Design Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Lab 302', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(context, 'Timetable', 'View your weekly schedule', const StudentScheduleScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Report Incident', 'Log issues related to equipment', const StudentReportIncidentScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Lab Instructions', 'Access practical documents', const StudentLabInstructionsScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Lab Rules', 'Read laboratory compliance guidelines', null),
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
