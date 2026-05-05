import 'package:flutter/material.dart';
import '../common/my_classes_schedule_screen.dart';
import 'lecturer_propose_schedule_screen.dart';

class LecturerScheduleHubScreen extends StatelessWidget {
  final String lecturerId;
  const LecturerScheduleHubScreen({super.key, required this.lecturerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Schedule Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: Color(0xFF1E1E1E))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        centerTitle: true,
      ),
      body: const MyClassesScheduleScreen(role: 'lecturer', hideAppBar: true),
    );
  }
}
