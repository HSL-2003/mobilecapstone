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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
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
                const SizedBox(height: 16),
                Text(
                  userData['name']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData['role']!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF26F21),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildInfoRow('Email', userData['email']!),
            _buildInfoRow('Student Code', userData['studentCode']!),
            _buildInfoRow('Date of Birth', userData['dob']!),
            _buildInfoRow('Address', userData['address']!),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('LOGOUT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }
}
