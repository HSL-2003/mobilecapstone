import 'package:flutter/material.dart';

class LecturerSessionManagementScreen extends StatelessWidget {
  const LecturerSessionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IoT Class SE1601 - Lab 3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: const Color(0xFF4361EE),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Equipment'),
              Tab(text: 'Groups'),
              Tab(text: 'Grading'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EquipmentTab(),
            _GroupsTab(),
            _GradingTab(),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pre-Session Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCheckItem('Oscilloscope x5', true),
        _buildCheckItem('Function Generator x5', true),
        _buildCheckItem('Breadboards x20', false),
        const SizedBox(height: 24),
        const Text('Post-Session Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Verify all tools are collected and note any damages.'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Damaged Equipment'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        )
      ],
    );
  }
  Widget _buildCheckItem(String title, bool isChecked) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: (v) {},
      title: Text(title, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF4361EE),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGroupCard('Group 1', '4/4 Present', Colors.green),
        const SizedBox(height: 16),
        _buildGroupCard('Group 2', '3/4 Present', Colors.orange),
        const SizedBox(height: 16),
        _buildGroupCard('Group 3', '4/4 Present', Colors.green),
      ],
    );
  }
  Widget _buildGroupCard(String title, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        children: [
          ListTile(leading: const Icon(Icons.person), title: const Text('Nguyen Van A (Leader)'), trailing: Checkbox(value: true, onChanged: (v){}, activeColor: const Color(0xFF4361EE))),
          ListTile(leading: const Icon(Icons.person), title: const Text('Le Thi B'), trailing: Checkbox(value: true, onChanged: (v){}, activeColor: const Color(0xFF4361EE))),
        ],
      ),
    );
  }
}

class _GradingTab extends StatelessWidget {
  const _GradingTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Submit Grades & Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildGradingForm('Group 1'),
        const Divider(height: 48),
        _buildGradingForm('Group 2'),
      ],
    );
  }
  Widget _buildGradingForm(String groupName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Grade (0-10)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
              child: const Text('Save Grade'),
            )
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Feedback (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
