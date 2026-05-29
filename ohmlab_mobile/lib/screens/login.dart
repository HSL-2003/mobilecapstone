import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '955586171979-4ns9kveogoh4kgehar869ut30184pb8e.apps.googleusercontent.com',
  );
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Sign out first to force the account selection prompt
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Gửi idToken (JWT) thay vì googleUser.id
      // Web dùng Google GSI cũng gửi JWT credential → BE verify JWT → lấy email → check DB
      final Map<String, dynamic> loginData = {
        'googleId': googleAuth.idToken,   // JWT token, khớp with web
        'email': googleUser.email,
      };

      // Call the loginGoogle API
      final ApiResponse response = await _userService.loginGoogle(loginData);
      
      if (response.status == 200) {
        print('=== Login thành công ===');
        print('User Info:');
        print('  - Email: ${googleUser.email}');
        print('  - Name: ${googleUser.displayName}');
        print('  - Google ID: ${googleUser.id}');
        print('  - Photo URL: ${googleUser.photoUrl}');
        print('Response Data: ${response.data}');
        print('========================');
        
        // Login successful, navigate to main screen
        if (mounted) {
          String userRole = 'student';
          final dynamic payload = response.data;
          if (payload is Map) {
            dynamic roleData;
            if (payload.containsKey('data') && payload['data'] is Map) {
              roleData = payload['data']['role'] ?? payload['data']['roleName'] ?? payload['data']['userRoleName'] ?? payload['data']['userRole'];
            }
            roleData ??= payload['role'] ?? payload['roleName'] ?? payload['userRoleName'] ?? payload['userRole'];
            
            if (roleData == null) {
              try {
                final profileResponse = await _userService.getCurrentUser();
                if (profileResponse.status == 200 || profileResponse.status == 201) {
                  final pData = profileResponse.data;
                  if (pData is Map) {
                    if (pData.containsKey('data') && pData['data'] is Map) {
                      roleData = pData['data']['userRoleName'] ?? pData['data']['role'];
                    } else {
                      roleData = pData['userRoleName'] ?? pData['role'];
                    }
                  }
                }
              } catch(e) {
                print("Lỗi fallback lấy role (Google): $e");
              }
            }

            if (roleData != null) {
              String rawRole = roleData.toString().toLowerCase();
              if (rawRole.contains('lecturer')) userRole = 'lecturer';
              else if (rawRole.contains('head')) userRole = 'head';
              else if (rawRole.contains('security')) userRole = 'security';
            }
          }
          Navigator.pushReplacementNamed(context, '/main', arguments: {'role': userRole});
        }
      } else {
        // Handle login error
        if (mounted) {
          final String errorMsg = response.message ?? 'Login error: ${response.status}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMsg\nData: ${response.data}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        String errorText = error.toString();
        // Cố gắng parse chi tiết lỗi nếu là DioException
        if (error.runtimeType.toString() == 'DioException' || error.runtimeType.toString() == 'DioError') {
          dynamic dioError = error;
          if (dioError.response != null) {
            errorText = 'Error code: ${dioError.response?.statusCode}\nDetails: ${dioError.response?.data}';
          } else {
            errorText = dioError.message ?? errorText;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection/API error: $errorText'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fpt_lab_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/fpt-logo.png', height: 80),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset('assets/images/google.png', height: 24),
                        label: Text(
                          _isLoading ? 'Logging in...' : 'Login with Google',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
