import 'package:flutter/material.dart';
import 'timetable.dart';
import 'incident_reports.dart';
import 'equipment.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _onScanPressed(BuildContext context) {
    // TODO: Implement scan functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Timetable',
        'color': Colors.orange,
        'destination': const TimetableScreen(),
      },
      {
        'icon': Icons.qr_code_scanner_rounded,
        'label': 'Scan',
        'color': Colors.orange,
        'destination': null,
      },
      {
        'icon': Icons.report_problem_rounded,
        'label': 'Incident Reports',
        'color': Colors.orange,
        'destination': const IncidentReportsScreen(),
      },
      {
        'icon': Icons.electrical_services_rounded,
        'label': 'Equipment',
        'color': Colors.orange,
        'destination': const EquipmentScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = features[index];
            return InkWell(
              onTap: () {
                if (item['destination'] == null) {
                  _onScanPressed(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['destination']),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], color: item['color'], size: 48),
                    const SizedBox(height: 10),
                    Text(
                      item['label'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
