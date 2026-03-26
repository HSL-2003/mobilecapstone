import 'package:flutter/material.dart';
import 'package:ohm_lab_mobile/screens/profile.dart';
import 'package:ohm_lab_mobile/screens/student/student_dashboard.dart';
import 'package:ohm_lab_mobile/screens/lecturer/lecturer_dashboard.dart';
import 'package:ohm_lab_mobile/screens/security/security_dashboard.dart';
import 'package:ohm_lab_mobile/screens/head/head_dashboard.dart';

class MainScreen extends StatefulWidget {
  final String role; // 'student', 'lecturer', 'security', 'head'
  
  const MainScreen({super.key, this.role = 'student'});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    Widget dashboard;
    switch (widget.role) {
      case 'lecturer':
        dashboard = const LecturerDashboard();
        break;
      case 'security':
        dashboard = const SecurityDashboard();
        break;
      case 'head':
        dashboard = const HeadDashboard();
        break;
      case 'student':
      default:
        dashboard = const StudentDashboard();
        break;
    }
    _screens = [dashboard, const ProfileScreen()];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _getRoleColor(widget.role),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'lecturer': return const Color(0xFF4361EE);
      case 'head': return const Color(0xFFBA1826);
      case 'security': return const Color(0xFF2B2D42);
      case 'student':
      default: return const Color(0xFFFB8500);
    }
  }
}
