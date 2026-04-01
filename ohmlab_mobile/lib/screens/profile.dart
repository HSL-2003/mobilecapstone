import 'package:flutter/material.dart';

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFF26F21),
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData['userFullName'] ?? _userData['name'] ?? 'Chưa cập nhật tên',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_userData['userRoleName'] ?? _userData['role'] ?? 'Unknown Role').toString().toUpperCase(),
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

                    _buildInfoRow('Email', _userData['userEmail'] ?? _userData['email'] ?? 'Chưa cập nhật'),
                    _buildInfoRow('Roll Number', _userData['userRollNumber'] ?? _userData['studentCode'] ?? 'Chưa cập nhật'),
                    _buildInfoRow('Number Code', _userData['userNumberCode'] ?? 'Chưa cập nhật'),
                    _buildInfoRow('Status', _userData['status'] ?? 'Active'),

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
