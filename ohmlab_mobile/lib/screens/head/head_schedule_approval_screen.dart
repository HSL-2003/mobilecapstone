import 'package:flutter/material.dart';

class HeadScheduleApprovalScreen extends StatelessWidget {
  const HeadScheduleApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Schedule Approvals', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildApprovalCard(context, 'SE1601 - IoT Fundamentals', 'Dr. Nguyen Van A', '12/10/2025 - Slot 1 (Lab 301)'),
          const SizedBox(height: 16),
          _buildApprovalCard(context, 'SE1603 - Embedded Systems', 'Dr. Tran Thi B', '14/10/2025 - Slot 2 (Lab 302)'),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, String course, String lecturer, String schedule) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Proposed by: $lecturer', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Schedule: $schedule', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: (){}, style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[800], side: BorderSide(color: Colors.grey[300]!)), child: const Text('Reject'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21), foregroundColor: Colors.white, elevation: 0), child: const Text('Approve'))),
            ],
          )
        ],
      ),
    );
  }
}
