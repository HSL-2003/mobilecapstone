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
  final emailCtrl = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Prepare data for API call
      // Prepare data for API call (Chỉ gửi googleId theo yêu cầu backend)
      final Map<String, dynamic> loginData = {
        'googleId': googleUser.id,
      };

      // Call the loginGoogle API
      final ApiResponse response = await _userService.loginGoogle(loginData);
      
      if (response.status == 200) {
        // Print user info
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản không tồn tại, vui lòng liên hệ admin cung cấp tài khoản'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản không tồn tại, vui lòng liên hệ admin cung cấp tài khoản'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
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

                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);
                          
                          // Chuẩn bị payload trực tiếp tới API test login
                          try {
                            final response = await _userService.loginTest(emailCtrl.text.trim());
                            
                            if (response.status == 200 || response.status == 201) {
                              if (context.mounted) {
                                String userRole = 'student'; // Mặc định
                                final dynamic payload = response.data;
                                if (payload is Map) {
                                  dynamic roleData;
                                  if (payload.containsKey('data') && payload['data'] is Map) {
                                    roleData = payload['data']['role'] ?? payload['data']['roleName'] ?? payload['data']['userRoleName'] ?? payload['data']['userRole'];
                                  }
                                  roleData ??= payload['role'] ?? payload['roleName'] ?? payload['userRoleName'] ?? payload['userRole'];
                                  
                                  // Lấy lại Role từ /current-user nếu endpoint đăng nhập không trả về
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
                                      print("Không thể lấy /current-user để tìm Role fallback: $e");
                                    }
                                  }

                                  if (roleData != null) {
                                    String rawRole = roleData.toString().toLowerCase();
                                    if (rawRole.contains('lecturer')) userRole = 'lecturer';
                                    else if (rawRole.contains('head')) userRole = 'head';
                                    else if (rawRole.contains('security')) userRole = 'security';
                                    else userRole = 'student';
                                  }
                                }
                                Navigator.pushReplacementNamed(context, '/main', arguments: {'role': userRole});
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tài khoản không tồn tại, vui lòng liên hệ admin cung cấp tài khoản'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tài khoản không tồn tại, vui lòng liên hệ admin cung cấp tài khoản'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF26F21),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                          _isLoading ? 'Đang đăng nhập...' : 'Login with Google',
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
