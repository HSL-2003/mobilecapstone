import 'package:flutter/material.dart';

class HeadLecturerAssignmentScreen extends StatelessWidget {
  const HeadLecturerAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturer Assignment'), backgroundColor: const Color(0xFFBA1826), foregroundColor: Colors.white),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Lecturer: $assignee', style: TextStyle(color: assigned ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        trailing: OutlinedButton(onPressed: (){}, child: Text(assigned ? 'Reassign' : 'Assign')),
      ),
    );
  }
}
