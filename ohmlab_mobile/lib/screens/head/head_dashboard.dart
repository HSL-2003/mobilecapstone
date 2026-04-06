import 'package:flutter/material.dart';
import 'head_class_management_screen.dart';
import 'head_lecturer_assignment_screen.dart';
import 'head_schedule_approval_screen.dart';
import '../common/daily_schedule_screen.dart';

class HeadDashboard extends StatelessWidget {
  const HeadDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Head of Department', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
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
              const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: InkWell(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyScheduleScreen()));
                      },
                      child: _buildStatCard('Classes Today', 'View'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Pending Approvals', '5')),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildListAction(context, 'Daily Report (Slots)', 'View today\'s teaching slots and classes', const DailyScheduleScreen()),
              const SizedBox(height: 12),
              _buildListAction(context, 'Schedule Approvals', 'Approve lecturer lab schedules', const HeadScheduleApprovalScreen()),
              const SizedBox(height: 12),
              _buildListAction(context, 'Lecturer Assignment', 'Assign lecturers to classes', const HeadLecturerAssignmentScreen()),
              const SizedBox(height: 12),
              _buildListAction(context, 'Class & Course Management', 'Update practical regulations', const HeadClassManagementScreen()),
              const SizedBox(height: 12),
              _buildListAction(context, 'Incident Reports', 'Review escalated incident reports', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF26F21), letterSpacing: -1.0)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildListAction(BuildContext context, String title, String subtitle, Widget? destination) {
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
