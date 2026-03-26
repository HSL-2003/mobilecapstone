import 'package:flutter/material.dart';

class SecurityRoomStatusScreen extends StatefulWidget {
  const SecurityRoomStatusScreen({super.key});

  @override
  State<SecurityRoomStatusScreen> createState() => _SecurityRoomStatusScreenState();
}

class _SecurityRoomStatusScreenState extends State<SecurityRoomStatusScreen> {
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Lab 301', 'status': 'Available', 'color': Colors.blue},
    {'name': 'Lab 302', 'status': 'In Use', 'color': Colors.green},
    {'name': 'Lab 303', 'status': 'Locked', 'color': Colors.redAccent},
    {'name': 'Lab 304', 'status': 'Maintenance', 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Update Room Status', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B2D42),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: room['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.meeting_room, color: room['color']),
              ),
              title: Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(room['status'], style: TextStyle(color: room['color'], fontWeight: FontWeight.bold)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onSelected: (newStatus) {
                  setState(() {
                    room['status'] = newStatus;
                    switch(newStatus) {
                      case 'Available': room['color'] = Colors.blue; break;
                      case 'In Use': room['color'] = Colors.green; break;
                      case 'Locked': room['color'] = Colors.redAccent; break;
                      case 'Maintenance': room['color'] = Colors.orange; break;
                    }
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Available', child: Text('Available')),
                  PopupMenuItem(value: 'In Use', child: Text('In Use')),
                  PopupMenuItem(value: 'Locked', child: Text('Locked')),
                  PopupMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
