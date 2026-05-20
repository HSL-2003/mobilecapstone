import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class SecurityCheckInScreen extends StatefulWidget {
  const SecurityCheckInScreen({super.key});

  @override
  State<SecurityCheckInScreen> createState() => _SecurityCheckInScreenState();
}

class _SecurityCheckInScreenState extends State<SecurityCheckInScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _userService.getAllRegistrationSchedules();
      if (res.status == 200 || res.status == 201) {
        final payload = res.data;
        List<dynamic> all = [];
        if (payload is List) {
          all = payload;
        } else if (payload is Map) {
          if (payload.containsKey('data') && payload['data'] is List) {
            all = payload['data'];
          } else if (payload.containsKey('items') && payload['items'] is List) {
            all = payload['items'];
          } else if (payload.containsKey('list') && payload['list'] is List) {
            all = payload['list'];
          } else if (payload.containsKey('pageData') && payload['pageData'] is List) {
            all = payload['pageData'];
          } else if (payload.containsKey('data') && payload['data'] is Map) {
            final innerData = payload['data'];
            if (innerData.containsKey('pageData') && innerData['pageData'] is List) {
              all = innerData['pageData'];
            } else if (innerData.containsKey('items') && innerData['items'] is List) {
              all = innerData['items'];
            } else if (innerData.containsKey('data') && innerData['data'] is List) {
              all = innerData['data'];
            }
          }
        }
        setState(() {
          // Filter: exclude Pending, Reject, Rejected, Completed
          final filtered = all.where((s) {
            final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString().toLowerCase();
            return status != 'pending' && status != 'reject' && status != 'rejected' && status != 'completed';
          }).toList();

          // Sort: newest date first
          filtered.sort((a, b) {
            final dateA = DateTime.tryParse(a['registraionScheduleDate']?.toString() ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['registraionScheduleDate']?.toString() ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          _schedules = filtered;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (res.status == 403) {
            _errorMessage = 'Security account is not authorized (Error 403). Please contact Admin.';
          } else {
            _errorMessage = 'Failed to load schedule list: ${res.message ?? res.status}';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorText = 'A system error occurred.';
      if (e.toString().contains('403')) {
        errorText = 'Account is not authorized (Error 403). Please contact Backend.';
      } else {
        errorText = 'Connection error: ${e.toString()}';
      }
      setState(() { _errorMessage = errorText; _isLoading = false; });
    }
  }

  Future<void> _doCheckIn(Map<String, dynamic> schedule) async {
    final int? scheduleId = int.tryParse(
      (schedule['registraionScheduleId'] ?? schedule['registrationScheduleId'] ?? schedule['id'] ?? '').toString()
    );
    final int? roomId = int.tryParse(
      (schedule['roomId'] ?? schedule['room']?['id'] ?? '').toString()
    );

    if (scheduleId == null || roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule or Room ID not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room: ${schedule['roomName'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Lecturer: ${schedule['lecturerName'] ?? schedule['teacherName'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            const Text('Confirm key has been handed over to the lecturer?',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF26F21),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Check-in', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.securityCheckIn(scheduleId);
      Navigator.pop(context);
      if (res.status == 200 || res.status == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in successful! Schedule is now In Progress.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in error: ${res.message ?? res.status}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Status Helpers ──
  bool _isAccepted(String status) {
    final s = status.toLowerCase();
    return s == 'accept' || s == 'accepted';
  }

  bool _isInProgress(String status) {
    return status.toLowerCase() == 'inprogress';
  }

  Color _statusColor(bool isOverdue) {
    if (isOverdue) return const Color(0xFFE53935);
    return const Color(0xFFF26F21);
  }

  // ── Section Header (gradient) ──
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: gradientColors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Empty Placeholder ──
  Widget _buildEmptyCard(IconData icon, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  // ── Schedule Card ──
  Widget _buildScheduleCard(dynamic s, bool canCheckIn, {required bool isOverdue}) {
    final String roomName = s['roomName'] ?? 'N/A';
    final String teacher = s['lecturerName'] ?? s['teacherName'] ?? s['teacherFullName'] ?? 'N/A';
    final String rawDate = s['registraionScheduleDate'] ?? s['registrationScheduleDate'] ?? '';
    String displayDate = rawDate;
    try {
      if (rawDate.isNotEmpty) {
        final dt = DateTime.parse(rawDate);
        displayDate = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      }
    } catch (_) {}

    final String startTime = s['slotStartTime'] ?? s['startTime'] ?? '';
    final String endTime = s['slotEndTime'] ?? s['endTime'] ?? '';
    final String slotName = s['slotName'] ?? '';
    final String className = s['className'] ?? '';

    final Color accentColor = canCheckIn
        ? (isOverdue ? const Color(0xFFE53935) : const Color(0xFFF26F21))
        : const Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Make-up banner
            if (isOverdue) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Overdue — Please notify the lecturer to perform make-up check-in',
                        style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    canCheckIn ? (isOverdue ? Icons.event_busy_outlined : Icons.meeting_room_outlined) : Icons.check_circle_outline,
                    color: accentColor, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roomName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E))),
                      if (className.isNotEmpty)
                        Text(className, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    canCheckIn ? (isOverdue ? 'Make-up' : 'Pending Check-in') : 'In Progress',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(teacher, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E1E1E)))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(displayDate, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_outlined, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slotName.isNotEmpty ? '$slotName ($startTime–$endTime)' : '$startTime–$endTime',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canCheckIn) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _doCheckIn(s),
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: Text(
                    isOverdue ? 'Make-up Check-in · Hand Over Key' : 'Check-in · Hand Over Key',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    shadowColor: accentColor.withOpacity(0.4),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: const Color(0xFF2196F3).withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text('Key successfully handed over',
                    style: TextStyle(color: const Color(0xFF2196F3).withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todaySchedules = _schedules.where((s) {
      final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString();
      if (!_isAccepted(status)) return false;
      final dt = DateTime.tryParse(s['registraionScheduleDate']?.toString() ?? '');
      if (dt == null) return false;
      return DateTime(dt.year, dt.month, dt.day) == todayDate;
    }).toList();

    final overdueSchedules = _schedules.where((s) {
      final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString();
      if (!_isAccepted(status)) return false;
      final dt = DateTime.tryParse(s['registraionScheduleDate']?.toString() ?? '');
      if (dt == null) return false;
      return DateTime(dt.year, dt.month, dt.day).isBefore(todayDate);
    }).toList();

    final inProgressSchedules = _schedules.where((s) {
      final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString();
      return _isInProgress(status);
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Lab Check-in',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadSchedules,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSchedules,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 90, left: 20, right: 20, bottom: 32),
                  children: [

                    // ── Section 1: Today's Check-in ──
                    _buildSectionHeader(
                      title: "Today's Check-in",
                      subtitle: 'Approved sessions scheduled for today',
                      icon: Icons.today_outlined,
                      count: todaySchedules.length,
                      gradientColors: const [Color(0xFFF26F21), Color(0xFFFFA726)],
                    ),
                    const SizedBox(height: 4),
                    if (todaySchedules.isEmpty)
                      _buildEmptyCard(Icons.event_available_outlined, 'No sessions scheduled for today')
                    else
                      ...todaySchedules.map((s) => _buildScheduleCard(s, true, isOverdue: false)),

                    const SizedBox(height: 16),

                    // ── Section 2: Overdue — Make-up Check-in ──
                    _buildSectionHeader(
                      title: 'Overdue · Make-up Check-in',
                      subtitle: 'Past sessions not yet checked in — notify lecturer',
                      icon: Icons.warning_amber_rounded,
                      count: overdueSchedules.length,
                      gradientColors: const [Color(0xFFE53935), Color(0xFFEF5350)],
                    ),
                    const SizedBox(height: 4),
                    if (overdueSchedules.isEmpty)
                      _buildEmptyCard(Icons.check_circle_outline, 'No overdue sessions — all caught up!')
                    else
                      ...overdueSchedules.map((s) => _buildScheduleCard(s, true, isOverdue: true)),

                    const SizedBox(height: 16),

                    // ── Section 3: In Progress ──
                    _buildSectionHeader(
                      title: 'In Progress',
                      subtitle: 'Key handed over · Lab session underway',
                      icon: Icons.play_circle_outline,
                      count: inProgressSchedules.length,
                      gradientColors: const [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    ),
                    const SizedBox(height: 4),
                    if (inProgressSchedules.isEmpty)
                      _buildEmptyCard(Icons.hourglass_empty_outlined, 'No sessions currently in progress')
                    else
                      ...inProgressSchedules.map((s) => _buildScheduleCard(s, false, isOverdue: false)),
                  ],
                ),
    );
  }
}
