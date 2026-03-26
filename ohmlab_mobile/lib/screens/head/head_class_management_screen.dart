import 'package:flutter/material.dart';

class HeadClassManagementScreen extends StatelessWidget {
  const HeadClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class & Course Management'), backgroundColor: const Color(0xFFBA1826), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildItem('Embedded Systems', '12 Active Classes - 4 Labs', Icons.developer_board),
          _buildItem('IoT Fundamentals', '8 Active Classes - 6 Labs', Icons.wifi),
          _buildItem('Circuit Design', '15 Active Classes - 5 Labs', Icons.electric_bolt),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFBA1826),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItem(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFBA1826), size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: (){}),
      ),
    );
  }
}
