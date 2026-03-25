import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = {
      'avatarUrl': 'https://i.pravatar.cc/150?img=47',
      'name': 'Nguyen Van A',
      'role': 'Lecturer', 
      'email': 'nguyenvana@fpt.edu.vn',
      'studentCode': 'SE180123',
      'dob': '12/08/2002',
      'address': 'District 9, Ho Chi Minh City',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userData['avatarUrl']!),
                ),
                const SizedBox(height: 12),
                Text(
                  userData['name']!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userData['role']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: userData['role'] == 'Lecturer'
                        ? Colors.blueAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildInfoRow(Icons.email, 'Email', userData['email']!),
            _buildInfoRow(
              Icons.badge,
              'Student Code',
              userData['studentCode']!,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Date of Birth',
              userData['dob']!,
            ),
            _buildInfoRow(Icons.home, 'Address', userData['address']!),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color:Colors.orange),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),

        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
