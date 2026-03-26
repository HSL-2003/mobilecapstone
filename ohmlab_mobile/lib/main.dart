import 'package:flutter/material.dart';
import 'package:ohm_lab_mobile/screens/main_screen.dart';
import 'screens/login.dart';

void main() {
  runApp(const OhmLabApp());
}

class OhmLabApp extends StatelessWidget {
  const OhmLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ohm Lab Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange, 
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming we use a modern font, otherwise default is fine
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final role = args?['role'] as String? ?? 'student';
          return MainScreen(role: role);
        },
      },
    );
  }
}
