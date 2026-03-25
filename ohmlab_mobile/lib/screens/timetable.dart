import 'package:flutter/material.dart';
import 'package:calendar_slider/calendar_slider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  DateTime _selectedDate = DateTime.now();

  // Fake data — sau này mày call API lấy lịch thật
  final Map<String, List<String>> _events = {
    '2025-10-08': ['Lab Session 1 - IoT', 'Project Review'],
    '2025-10-09': ['Circuit Design Practice'],
    '2025-10-10': ['Soldering Workshop', 'Team Meeting'],
  };

  List<String> getEvents(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = getEvents(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable'), centerTitle: true, backgroundColor: Colors.orange, foregroundColor: Colors.white,),
      body: Column(
        children: [
          CalendarSlider(
            selectedDateColor: Colors.white,
            backgroundColor: Colors.white,
            selectedDayPosition: SelectedDayPosition.center,
            monthYearButtonBackgroundColor: Colors.blue,
            initialDate: _selectedDate,
            firstDate: DateTime(2024),
            lastDate: DateTime(2026),
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No events for this date',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(event),
                          subtitle: const Text('08:00 - 10:00'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
