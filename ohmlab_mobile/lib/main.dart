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
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) =>
            MainScreen(), 
      },
    );
  }
}
