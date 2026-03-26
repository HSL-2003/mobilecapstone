import 'package:flutter/material.dart';

class StudentLabInstructionsScreen extends StatelessWidget {
  const StudentLabInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Circuit Design Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: const Color(0xFFFB8500),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Instructions'),
              Tab(text: 'My Group'),
              Tab(text: 'Submission'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InstructionsTab(),
            _GroupTab(),
            _SubmissionTab(),
          ],
        ),
      ),
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  const _InstructionsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Objective', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Build a functional 555-timer circuit on a breadboard to blink an LED at 1Hz.'),
        const SizedBox(height: 24),
        const Text('Required Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.build),
          title: const Text('Breadboard x1'),
          tileColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.precision_manufacturing),
          title: const Text('555 Timer IC x1'),
          tileColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          title: const Text('LED & Resistors x5'),
          tileColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Group 4', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildMember('Nguyen Van A', 'SE180123', true),
        const SizedBox(height: 12),
        _buildMember('Tran Thi B', 'SE180124', false),
        const SizedBox(height: 12),
        _buildMember('Le Van C', 'SE180125', false),
      ],
    );
  }

  Widget _buildMember(String name, String rollId, bool isLeader) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFFB8500), child: Text(name[0], style: const TextStyle(color: Colors.white))),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(rollId),
      trailing: isLeader ? const Chip(label: Text('Leader', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFFD166)) : null,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
    );
  }
}

class _SubmissionTab extends StatelessWidget {
  const _SubmissionTab();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(child: const Text('Your grade: 9.0/10\nFeedback: Good practical work!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Submit Lab Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Only the Group Leader can submit the final report link.'),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Link to Google Drive / Report Document...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Submit Report'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB8500), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          )
        ],
      ),
    );
  }
}
