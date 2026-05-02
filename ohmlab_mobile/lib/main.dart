import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ohm_lab_mobile/screens/main_screen.dart';
import 'screens/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF26F21)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
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
