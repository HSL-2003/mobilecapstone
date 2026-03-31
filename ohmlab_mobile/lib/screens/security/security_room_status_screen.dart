import 'package:flutter/material.dart';

class SecurityRoomStatusScreen extends StatefulWidget {
  const SecurityRoomStatusScreen({super.key});

  @override
  State<SecurityRoomStatusScreen> createState() => _SecurityRoomStatusScreenState();
}

class _SecurityRoomStatusScreenState extends State<SecurityRoomStatusScreen> {
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Lab 301', 'status': 'Available', 'color': const Color(0xFFF26F21)},
    {'name': 'Lab 302', 'status': 'In Use', 'color': const Color(0xFFF26F21)},
    {'name': 'Lab 303', 'status': 'Locked', 'color': const Color(0xFFF26F21)},
    {'name': 'Lab 304', 'status': 'Maintenance', 'color': const Color(0xFFF26F21)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Update Room Status', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
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
              border: Border.all(color: Colors.grey[200]!)
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
                      case 'Available': room['color'] = const Color(0xFFF26F21); break;
                      case 'In Use': room['color'] = const Color(0xFFF26F21); break;
                      case 'Locked': room['color'] = const Color(0xFFF26F21); break;
                      case 'Maintenance': room['color'] = const Color(0xFFF26F21); break;
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
