import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/screens/lecturer/lecturer_session_management_screen.dart';

class LecturerTeamsListScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const LecturerTeamsListScreen({super.key, required this.classData});

  @override
  State<LecturerTeamsListScreen> createState() => _LecturerTeamsListScreenState();
}

class _LecturerTeamsListScreenState extends State<LecturerTeamsListScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _teams = [];

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final int? classId = int.tryParse(widget.classData['classId']?.toString() ?? '');
      if (classId == null) {
        setState(() {
          _errorMessage = "Class ID not found.";
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
            _errorMessage = res.message ?? "Failed to load team list.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Server connection error.";
        });
      }
    }
  }

  Widget _buildTeamCard(BuildContext context, Map<String, dynamic> team) {
    final String teamName = team['teamName'] ?? team['name'] ?? 'Unnamed Team';
    final String details = "Team ID: ${team['id'] ?? team['teamId'] ?? '-'}";
    final rawId = team['id'] ?? team['teamId'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LecturerSessionManagementScreen(
              teamData: {
                "id": rawId,
                "teamId": rawId,
                "teamName": teamName,
                "className": widget.classData['className'],
                ...team,
              },
            ),
          ),
        );
      },
      child: Container(
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
        child: Row(
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
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
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
        child: Text('No students found in the class list.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final String name = user['userFullName'] ?? user['userName'] ?? user['fullName'] ?? user['name'] ?? 'Unknown User';
        final String code = user['userCode'] ?? user['studentCode'] ?? user['code'] ?? 'N/A';
        final String? userId = user['id']?.toString() ?? user['userId']?.toString();
        
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
              IconButton(
                icon: const Icon(Icons.group_add, color: Color(0xFFF26F21)),
                onPressed: () {
                  if (userId != null) {
                    _showTeamSelector(userId, name);
                  }
                },
                tooltip: 'Add to team',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTeamSelector(String userId, String userName) async {
    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class currently has no teams.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add \$userName to team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 16),
            const Text('Select a team to add this student to:', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _teams.length,
                itemBuilder: (context, idx) {
                  final team = _teams[idx];
                  final String teamName = team['teamName'] ?? 'Nhóm ${idx + 1}';
                  final teamId = team['teamId'] ?? team['id'];

                  return ListTile(
                    leading: const Icon(Icons.groups, color: Color(0xFFF26F21)),
                    title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _addUserToTeam(userId, teamId);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addUserToTeam(String userId, dynamic teamId) async {
    final int? tId = int.tryParse(teamId.toString());
    if (tId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.addUsersToTeam([
        {"teamId": tId, "userId": userId}
      ]);
      Navigator.pop(context);

      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student successfully added to team!'), backgroundColor: Colors.green));
          _fetchTeams(); // Refresh to update member counts if visible
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server connection error.'), backgroundColor: Colors.red));
      }
    }
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
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_teams.isEmpty) {
      return const Center(child: Text('No teams found in this class.', style: TextStyle(color: Colors.grey)));
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
    final String className = widget.classData['className'] ?? 'Class Details';

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
                  Tab(text: 'Students (Class Users)'),
                  Tab(text: 'Team List'),
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
