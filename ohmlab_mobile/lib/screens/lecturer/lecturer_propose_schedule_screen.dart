import 'package:flutter/material.dart';

class LecturerProposeScheduleScreen extends StatefulWidget {
  const LecturerProposeScheduleScreen({super.key});

  @override
  State<LecturerProposeScheduleScreen> createState() => _LecturerProposeScheduleScreenState();
}

class _LecturerProposeScheduleScreenState extends State<LecturerProposeScheduleScreen> {
  String _selectedCourse = 'Embedded Systems';
  String _selectedClass = 'SE1601';
  DateTime _selectedDate = DateTime.now();
  int _groupSize = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Propose Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4361EE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Class Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDropdown('Course', ['Embedded Systems', 'IoT Fundamentals', 'Circuit Design'], _selectedCourse, (v) => setState(() => _selectedCourse = v!)),
            const SizedBox(height: 16),
            _buildDropdown('Class', ['SE1601', 'SE1602', 'IA1603'], _selectedClass, (v) => setState(() => _selectedClass = v!)),
            const SizedBox(height: 32),
            const Text('Schedule Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Preferred Date'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4361EE))),
              trailing: const Icon(Icons.calendar_today, color: Color(0xFF4361EE)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const Divider(),
            _buildDropdown('Time Slot', ['Slot 1 (07:30 - 09:50)', 'Slot 2 (10:00 - 12:20)', 'Slot 3 (12:50 - 15:10)'], 'Slot 1 (07:30 - 09:50)', (v) {}),
            const SizedBox(height: 32),
            const Text('Student Grouping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Students per Group'),
                Row(
                  children: [
                    IconButton(onPressed: () => setState(() => _groupSize = _groupSize > 1 ? _groupSize - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_groupSize', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => setState(() => _groupSize++), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('System will automatically generate groups and assign leaders based on random selection.', style: TextStyle(color: Colors.blue, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule proposal submitted to Head of Department.'), backgroundColor: Colors.green));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Submit Proposal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
