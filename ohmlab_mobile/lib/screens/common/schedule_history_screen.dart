import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/api_service.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  final String role; // 'lecturer' or 'security'
  final bool hideAppBar;

  const ScheduleHistoryScreen({super.key, required this.role, this.hideAppBar = false});

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _historySchedules = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status != 200 && userResponse.status != 201) {
        throw Exception('Invalid login session.');
      }

      final payload = userResponse.data;
      dynamic userData = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
      final String? fetchedId = userData['id']?.toString() ?? userData['userId']?.toString() ?? userData['lecturerId']?.toString();

      if (fetchedId == null) throw Exception('User ID not found.');

      ApiResponse res;
      if (widget.role == 'lecturer') {
        res = await _userService.getRegistrationSchedulesByTeacherId(fetchedId);
      } else {
        res = await _userService.getAllRegistrationSchedules();
      }

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
        
        // Sort by date descending
        all.sort((a, b) {
          final dateA = DateTime.tryParse(a['registraionScheduleDate']?.toString() ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b['registraionScheduleDate']?.toString() ?? '') ?? DateTime(0);
          return dateB.compareTo(dateA);
        });

        // Filter: For security, only display completed and inprogress. For others, exclude pending.
        _historySchedules = all.where((s) {
          final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString().toLowerCase();
          if (widget.role == 'security') {
            return status == 'completed' || status == 'inprogress';
          }
          return status != 'pending';
        }).toList();
        setState(() => _isLoading = false);
      } else {
        setState(() { _errorMessage = res.message ?? 'Failed to load history.'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.startsWith('0001-01-01')) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Schedule History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: const Color(0xFFF26F21),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            : _historySchedules.isEmpty
              ? const Center(child: Text('No history available.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historySchedules.length,
                  itemBuilder: (context, index) {
                    final s = _historySchedules[index];
                    final String className = s['className'] ?? 'Unknown Class';
                    final String roomName = s['roomName'] ?? s['room']?['roomName'] ?? 'Unknown Room';
                    final String dateStr = _formatDateTime(s['registraionScheduleDate']);
                    final String checkIn = _formatDateTime(s['registraionScheduleCheckIn']);
                    final String checkOut = _formatDateTime(s['registraionScheduleCheckOut']);
                    final String status = s['registraionScheduleStatus'] ?? 'Unknown';

                    Color statusColor = Colors.grey;
                    if (status.toLowerCase() == 'accepted') statusColor = Colors.green;
                    if (status.toLowerCase() == 'inprogress') statusColor = Colors.blue;
                    if (status.toLowerCase() == 'finished' || status.toLowerCase() == 'checkout') statusColor = Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E1E))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Date: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.meeting_room, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Room: $roomName', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Check-in (Security)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(checkIn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Check-out (Teacher)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(checkOut, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
