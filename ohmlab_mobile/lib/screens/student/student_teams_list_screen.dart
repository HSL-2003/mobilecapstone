import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/screens/student/student_equipment_history_screen.dart';
import 'package:ohm_lab_mobile/screens/student/student_kit_history_screen.dart';

class StudentTeamsListScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const StudentTeamsListScreen({super.key, required this.classData});

  @override
  State<StudentTeamsListScreen> createState() => _StudentTeamsListScreenState();
}

class _StudentTeamsListScreenState extends State<StudentTeamsListScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _teams = [];
  String? _currentStudentId;
  int? _myTeamId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchCurrentUser();
    await _fetchTeams();
    _findMyTeam();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final res = await _userService.getCurrentUser();
      if (res.status == 200 || res.status == 201) {
        final data = res.data is Map && res.data.containsKey('data') ? res.data['data'] : res.data;
        _currentStudentId = data['id']?.toString() ?? data['userId']?.toString();
      }
    } catch (_) {}
  }

  void _findMyTeam() {
    if (_currentStudentId == null || _teams.isEmpty) return;
    
    // We would need to fetch members for each team to strictly find 'my' team,
    // but for now let's assume we can show 'View Grade' for any team the student clicks
    // as long as they are authorized by the backend.
  }

  Future<void> _fetchTeams() async {
    try {
      final int? classId = int.tryParse(widget.classData['classId']?.toString() ?? '');
      if (classId == null) {
        setState(() {
          _errorMessage = "Không tìm thấy Class ID.";
          _isLoading = false;
        });
        return;
      }

      final res = await _userService.getTeamsByClassId(classId);
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            final payload = res.data;
            if (payload is Map && payload.containsKey('data')) {
              _teams = payload['data'] is List ? payload['data'] : [];
            } else if (payload is List) {
              _teams = payload;
            } else {
              _teams = [];
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = res.message ?? "Lỗi tải danh sách nhóm.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Lỗi kết nối máy chủ.";
        });
      }
    }
  }

  Widget _buildTeamCard(BuildContext context, Map<String, dynamic> team) {
    final String teamName = team['teamName'] ?? team['name'] ?? 'Nhóm chưa đặt tên';
    final String details = "Team ID: ${team['id'] ?? team['teamId'] ?? '-'}";
    final int? rawId = int.tryParse((team['id'] ?? team['teamId'] ?? '').toString());

    return GestureDetector(
      onTap: () {
        if (rawId != null) {
          _showGradeDialog(rawId, teamName);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.group, color: Color(0xFFF26F21), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(details, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Xem điểm', style: TextStyle(color: Color(0xFFF26F21), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Icon(Icons.stars, color: Color(0xFFF26F21), size: 18),
                  ],
                ),
              ],
            ),
            if (rawId != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentEquipmentHistoryScreen(teamId: rawId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.handyman, size: 16),
                      label: const Text('Lịch sử thiết bị', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF26F21),
                        side: BorderSide(color: const Color(0xFFF26F21).withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentKitHistoryScreen(teamId: rawId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.inventory_2, size: 16),
                      label: const Text('Lịch sử Kit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF26F21),
                        side: BorderSide(color: const Color(0xFFF26F21).withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _showGradeDialog(int teamId, String teamName) async {
    // We need a labId. For now, try to get it from classData or use a fallback.
    final int labId = int.tryParse(widget.classData['labId']?.toString() ?? '1') ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.getGrade(labId, teamId);
      Navigator.pop(context);

      if (res.status == 200 || res.status == 201) {
        final rawData = res.data is Map && res.data.containsKey('data') ? res.data['data'] : res.data;
        if (rawData != null && rawData is Map && rawData.isNotEmpty) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
          _displayGradeInfo(teamName, data);
        } else {
          _showNoGradeInfo(teamName);
        }
      } else {
        _showErrorDialog('Lỗi: ${res.message ?? "Không thể lấy thông tin điểm."}');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Lỗi kết nối máy chủ.');
    }
  }

  void _displayGradeInfo(String teamName, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.military_tech, color: Color(0xFFF26F21), size: 48),
            const SizedBox(height: 8),
            Text('Điểm số - $teamName', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF26F21).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                data['grade']?.toString() ?? '?',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFF26F21)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              data['gradeDescription']?.toString() ?? 'Chưa có nhận xét từ giảng viên.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Trạng thái: ${data['gradeStatus'] ?? "N/A"}',
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFFF26F21), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNoGradeInfo(String teamName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Thông báo', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Nhóm $teamName chưa có điểm số cho Lab này.', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Widget _buildStudentList() {
    List<dynamic> users = [];
    if (widget.classData['classUsers'] != null && widget.classData['classUsers'] is List) {
      users = widget.classData['classUsers'];
    }

    if (users.isEmpty) {
      return const Center(
        child: Text('Không có sinh viên nào trong danh sách lớp.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final String name = user['userName'] ?? user['fullName'] ?? user['name'] ?? 'Unknown User';
        final String code = user['userCode'] ?? user['studentCode'] ?? user['code'] ?? 'N/A';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF26F21).withOpacity(0.1),
                radius: 24,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFFF26F21), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E))),
                    const SizedBox(height: 4),
                    Text('Code: $code', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)));
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchTeams();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_teams.isEmpty) {
      return const Center(child: Text('Không có nhóm nào trong lớp này.', style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildTeamCard(context, _teams[index] as Map<String, dynamic>),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String className = widget.classData['className'] ?? 'Chi tiết Lớp';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 20, color: Color(0xFF1E1E1E))),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF26F21),
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Sinh viên (Class Users)'),
                  Tab(text: 'Danh sách Team'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentList(),
            _buildTeamsTab(),
          ],
        ),
      ),
    );
  }
}
