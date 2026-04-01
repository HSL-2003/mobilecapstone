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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),

            Image.asset('assets/images/fpt-logo.png', height: 100),
            const SizedBox(height: 40),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
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
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR'),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),

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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
