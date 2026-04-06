import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _userService.getCurrentUser();
      if (response.status == 200 || response.status == 201) {
        if (mounted) {
          setState(() {
            if (response.data is Map && response.data.containsKey('data') && response.data['data'] != null) {
              _userData = Map<String, dynamic>.from(response.data['data']);
            } else {
              _userData = Map<String, dynamic>.from(response.data);
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _errorMessage = 'Không thể tải thông tin. (Code: ${response.status})'; _isLoading = false; });
      }
    } catch (e) {
      print('Profile fetch error: $e');
      if (mounted) setState(() { 
        String errMsg = e.toString();
        if (errMsg.contains('DioException [bad response]')) {
             if (errMsg.contains('401')) errMsg = 'Token hết hạn hoặc không hợp lệ (401)';
             else errMsg = 'Lỗi Server Backend';
        }
        _errorMessage = 'Phiên rỗng, vui lòng đăng xuất ra rồi Đăng Nhập Lại. ($errMsg)'; 
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          // TODO: Có thể gọi UserService.logout() để xoá CSDL nội bộ
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('ĐĂNG XUẤT LẠI', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF26F21), Color(0xFFFFA726)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 50, color: Color(0xFFF26F21)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userData['userFullName'] ?? _userData['name'] ?? 'Chưa cập nhật tên',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              (_userData['userRoleName'] ?? _userData['role'] ?? 'Unknown Role').toString().toUpperCase(),
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                _buildInfoRow('Email', _userData['userEmail'] ?? _userData['email'] ?? 'Chưa cập nhật', Icons.email_outlined),
                                _buildInfoRow('Roll Number', _userData['userRollNumber'] ?? _userData['studentCode'] ?? 'Chưa thiết lập', Icons.badge_outlined),
                                _buildInfoRow('Student Code', _userData['userNumberCode'] ?? 'Chưa thiết lập', Icons.numbers),
                                _buildInfoRow('Status', _userData['status'] ?? 'Active', Icons.verified_user_outlined, isLast: true),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF0F0),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 8),
                                  Text('LOGOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.grey[500], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
