import 'package:flutter/material.dart';
import 'package:calendar_slider/calendar_slider.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  // Mock data tailored for students demonstrating group work & lab instructions
  final Map<String, List<Map<String, String>>> _events = {};

  List<Map<String, String>> getEvents(DateTime date) {
    // For demo purposes, let's always return a mock event if it's the selected date
    if (date.day == DateTime.now().day) {
      return [
        {
          'title': 'Circuit Design Practice',
          'time': '14:00 - 16:30',
          'room': 'Lab 302',
          'lecturer': 'Dr. Nguyen Van A',
          'group': 'Group 4',
          'status': 'Upcoming',
        }
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final events = getEvents(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFB8500),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFB8500),
            padding: const EdgeInsets.only(bottom: 16),
            child: CalendarSlider(
              selectedDateColor: const Color(0xFFFB8500),
              selectedTileBackgroundColor: Colors.white,
              monthYearButtonBackgroundColor: Colors.white24,
              monthYearTextColor: Colors.white,
              dateColor: Colors.white,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No lab sessions', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildScheduleCard(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, String> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Color(0xFFFB8500)),
                    const SizedBox(width: 8),
                    Text(
                      event['time']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFB8500)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event['status']!,
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(event['room']!, style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(width: 24),
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(event['group']!, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(event['lecturer']!, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to details / instructions
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFB8500),
                      side: const BorderSide(color: Color(0xFFFB8500)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Practical Instructions'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
