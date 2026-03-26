import 'package:flutter/material.dart';
import 'head_class_management_screen.dart';
import 'head_lecturer_assignment_screen.dart';
import 'head_schedule_approval_screen.dart';

class HeadDashboard extends StatelessWidget {
  const HeadDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Head of Department', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFBA1826), Color(0xFF9D0208)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.account_balance, size: 80, color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Active Classes', '24', Icons.class_)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Pending Approvals', '5', Icons.pending_actions)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildListAction(context, 'Schedule Approvals', 'Approve lecturer lab schedules', Icons.edit_calendar, Colors.orange, const HeadScheduleApprovalScreen()),
                  const SizedBox(height: 12),
                  _buildListAction(context, 'Lecturer Assignment', 'Assign lecturers to classes', Icons.people, Colors.blue, const HeadLecturerAssignmentScreen()),
                  const SizedBox(height: 12),
                  _buildListAction(context, 'Class & Course Management', 'Update practical regulations', Icons.library_books, Colors.green, const HeadClassManagementScreen()),
                  const SizedBox(height: 12),
                  _buildListAction(context, 'Incident Reports', 'Review escalated incident reports', Icons.warning, Colors.red, null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFBA1826)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildListAction(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget? destination) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        onTap: () {
          if (destination != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
