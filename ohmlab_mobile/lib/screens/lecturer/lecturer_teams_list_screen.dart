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
  List<dynamic> _classUsers = [];
  Map<int, dynamic> _teamGrades = {};

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

      // Fetch Teams
      final res = await _userService.getTeamsByClassId(classId);
      
      // Fetch Class Users
      final classRes = await _userService.getClassById(classId);

      // Fetch Grades for the current schedule
      final int? scheduleId = int.tryParse(widget.classData['registraionScheduleId']?.toString() ?? '');
      if (scheduleId != null) {
        try {
          final gradeRes = await _userService.getGradesByScheduleId(scheduleId);
          if (gradeRes.status == 200 || gradeRes.status == 201) {
             final gPayload = gradeRes.data;
             if (gPayload is Map && gPayload.containsKey('data') && gPayload['data'] is List) {
                for (var g in gPayload['data']) {
                   if (g is Map && g['teamId'] != null) {
                      final tId = int.tryParse(g['teamId'].toString());
                      if (tId != null) {
                         _teamGrades[tId] = g;
                      }
                   }
                }
             }
          }
        } catch (_) {}
      }

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

            // Extract Class Users
            if (classRes.status == 200 || classRes.status == 201) {
              final cPayload = classRes.data;
              if (cPayload is Map && cPayload.containsKey('data')) {
                final clsData = cPayload['data'];
                if (clsData is Map && clsData.containsKey('classUsers')) {
                  _classUsers = clsData['classUsers'] is List ? clsData['classUsers'] : [];
                }
              }
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
                ...team,
                "id": rawId,
                "teamId": rawId,
                "teamName": teamName,
                "className": widget.classData['className'],
                "registraionScheduleId": widget.classData['registraionScheduleId'],
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
            if (_teamGrades.containsKey(rawId))
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_teamGrades[rawId]['gradeScore'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                       _showUpdateGradeDialog(team, _teamGrades[rawId]);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    List<dynamic> users = _classUsers.isNotEmpty ? _classUsers : [];
    if (users.isEmpty && widget.classData['classUsers'] != null && widget.classData['classUsers'] is List) {
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
            Text('Add $userName to team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E1E))),
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

  void _showUpdateGradeDialog(Map<String, dynamic> team, Map<String, dynamic> gradeData) {
    final TextEditingController gradeCtrl = TextEditingController(text: gradeData['gradeScore']?.toString() ?? '');
    final TextEditingController descCtrl = TextEditingController(text: gradeData['gradeDescription']?.toString() ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Update Grade - ${team['teamName'] ?? 'Team'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: gradeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Grade Score (0-10)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Evaluation Feedback',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final double? score = double.tryParse(gradeCtrl.text.trim());
                          if (score == null || score < 0 || score > 10) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid grade score!'), backgroundColor: Colors.orange));
                            return;
                          }

                          setStateDialog(() {
                            isSaving = true;
                          });

                          final num gradeVal = score == score.toInt() ? score.toInt() : score;
                          final String desc = descCtrl.text.trim().isEmpty ? "None" : descCtrl.text.trim();

                          final payload = {
                            "gradeId": gradeData['gradeId'],
                            "teacherId": gradeData['teacherId'],
                            "registraionScheduleId": gradeData['registraionScheduleId'] ?? widget.classData['registraionScheduleId'],
                            "teamId": gradeData['teamId'] ?? team['id'],
                            "gradeScore": gradeVal,
                            "gradeDescription": desc,
                            "gradeDate": gradeData['gradeDate'] ?? DateTime.now().toIso8601String(),
                            "gradeStatus": gradeData['gradeStatus'] ?? "Valid"
                          };

                          try {
                            final res = await _userService.updateGrade(payload);
                            if (res.status == 200 || res.status == 201) {
                              Navigator.pop(context);
                              _fetchTeams(); // Reload to reflect changes
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade updated successfully!'), backgroundColor: Colors.green));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to update grade.'), backgroundColor: Colors.red));
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server.'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) {
                              setStateDialog(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateTeamDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Create New Team', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final String name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team name cannot be empty!'), backgroundColor: Colors.orange));
                            return;
                          }

                          setStateDialog(() {
                            isSaving = true;
                          });

                          final int? classId = int.tryParse(widget.classData['classId']?.toString() ?? '');
                          
                          final payload = {
                            "classId": classId ?? 0,
                            "teamName": name,
                            "teamDescription": descCtrl.text.trim(),
                            "teamStatus": "Active"
                          };

                          try {
                            final res = await _userService.createTeam(payload);
                            if (res.status == 200 || res.status == 201) {
                              Navigator.pop(context);
                              _fetchTeams(); // Reload teams
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created successfully!'), backgroundColor: Colors.green));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to create team.'), backgroundColor: Colors.red));
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) {
                              setStateDialog(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateTeamDialog,
          backgroundColor: const Color(0xFFF26F21),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Create Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
