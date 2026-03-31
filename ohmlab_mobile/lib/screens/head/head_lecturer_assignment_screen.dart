import 'package:flutter/material.dart';

class HeadLecturerAssignmentScreen extends StatelessWidget {
  const HeadLecturerAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Assignment', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
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
          _buildAssignmentCard('SE1601 - Embedded Systems', 'Not Assigned', false),
          const SizedBox(height: 16),
          _buildAssignmentCard('SE1602 - IoT Fundamentals', 'Dr. Nguyen Van A', true),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(String title, String assignee, bool assigned) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Lecturer: $assignee', style: TextStyle(color: assigned ? const Color(0xFFF26F21) : Colors.red, fontWeight: FontWeight.bold)),
        trailing: OutlinedButton(onPressed: (){}, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF26F21), side: const BorderSide(color: Color(0xFFF26F21))), child: Text(assigned ? 'Reassign' : 'Assign')),
      ),
    );
  }
}
