import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class LecturerEquipmentHistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  const LecturerEquipmentHistoryScreen({super.key, this.hideAppBar = false});

  @override
  State<LecturerEquipmentHistoryScreen> createState() => _LecturerEquipmentHistoryScreenState();
}

class _LecturerEquipmentHistoryScreenState extends State<LecturerEquipmentHistoryScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _equipmentHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status == 200 || userResponse.status == 201) {
        final payload = userResponse.data;
        dynamic userData;
        if (payload is Map && payload.containsKey('data') && payload['data'] != null) {
          userData = payload['data'];
        } else {
          userData = payload;
        }

        final String? lecturerId = userData['id']?.toString() ?? userData['userId']?.toString();

        if (lecturerId != null) {
          final histResponse = await _userService.searchTeamEquipmentByLecturerId(lecturerId: lecturerId);
          if (histResponse.status == 200 || histResponse.status == 201) {
            if (mounted) {
              setState(() {
                final histPayload = histResponse.data;
                if (histPayload is Map && histPayload.containsKey('data')) {
                  final pageData = histPayload['data']['pageData'];
                  _equipmentHistory = pageData is List ? pageData : [];
                } else {
                  _equipmentHistory = [];
                }
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = 'Cannot load equipment history.';
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Lecturer information not found.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication error.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Server connection error.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _giveBack(int teamEquipmentId) async {
    setState(() => _isLoading = true);
    try {
      final res = await _userService.giveBackEquipment(teamEquipmentId);
      if (res.status == 200 || res.status == 201) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipment returned successfully!'), backgroundColor: Colors.green));
        _fetchHistory();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.message}'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error while returning equipment.'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.hideAppBar ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Equipment History', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
        : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))))
          : _equipmentHistory.isEmpty
            ? const Center(child: Text("Team has no equipment borrow/return history.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, left: 24, right: 24, bottom: 24),
                itemCount: _equipmentHistory.length,
                itemBuilder: (context, index) {
                  final hist = _equipmentHistory[index];

                  final String rawBorrowDate = hist['teamEquipmentDateBorrow']?.toString() ?? '';
                  String displayDate = 'N/A';
                  String borrowTime = 'N/A';
                  if (rawBorrowDate.isNotEmpty && rawBorrowDate != 'null') {
                    try {
                      final dt = DateTime.parse(rawBorrowDate).toLocal();
                      displayDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                      borrowTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final String rawGiveBackDate = hist['teamEquipmentDateGiveBack']?.toString() ?? '';
                  String? returnTime;
                  if (rawGiveBackDate.isNotEmpty && rawGiveBackDate != 'null') {
                    try {
                      final dt = DateTime.parse(rawGiveBackDate).toLocal();
                      returnTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final String teamName = hist['teamName']?.toString() ?? 'Unknown Team';
                  final String className = hist['className']?.toString() ?? '';
                  final String equipmentName = hist['equipmentName']?.toString() ?? 'Unnamed Equipment';
                  final String eqCode = hist['equipmentCode']?.toString() ?? '-';

                  final String rawStatus = hist['teamEquipmentStatus']?.toString() ?? 'Unknown';
                  final String status = rawStatus == 'AreBorrowing' ? 'In Use' : (rawStatus == 'GiveBack' ? 'Returned' : rawStatus);
                  final Color statusColor = status == 'Returned' ? Colors.green : Colors.orange;

                  final int? teamEquipmentId = int.tryParse(hist['teamEquipmentId']?.toString() ?? '');

                  return GestureDetector(
                    onTap: () {
                      if (teamEquipmentId != null) {
                        _showEquipmentDetailModal(teamEquipmentId);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.handyman, color: Color(0xFFF26F21), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.group_outlined, 'Class/Team', '$className - $teamName'),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.developer_board, 'Equipment', '$equipmentName ($eqCode)'),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTimeBadge(Icons.call_made, 'Borrow: $borrowTime', Colors.blue),
                                if (returnTime != null && returnTime.isNotEmpty && returnTime != 'null')
                                  _buildTimeBadge(Icons.call_received, 'Return: $returnTime', Colors.green)
                                else if (teamEquipmentId != null)
                                  OutlinedButton.icon(
                                    onPressed: () => _giveBack(teamEquipmentId),
                                    icon: const Icon(Icons.assignment_return, size: 16),
                                    label: const Text('Give Back'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFF26F21),
                                      side: const BorderSide(color: Color(0xFFF26F21)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  )
                                else
                                  _buildTimeBadge(Icons.timer, 'Not Returned', Colors.orange),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _showEquipmentDetailModal(int id) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EquipmentDetailModal(equipmentId: id, userService: _userService),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)))),
      ],
    );
  }

  Widget _buildTimeBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EquipmentDetailModal extends StatefulWidget {
  final int equipmentId;
  final UserService userService;

  const _EquipmentDetailModal({required this.equipmentId, required this.userService});

  @override
  State<_EquipmentDetailModal> createState() => _EquipmentDetailModalState();
}

class _EquipmentDetailModalState extends State<_EquipmentDetailModal> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await widget.userService.getTeamEquipmentById(widget.equipmentId);
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            _data = res.data is Map && res.data.containsKey('data') ? res.data['data'] : res.data;
            _isLoading = false;
          });
        }
      } else {
         if (mounted) setState(() { _error = 'Error: ${res.message}'; _isLoading = false; });
      }
    } catch(e) {
       if (mounted) setState(() { _error = 'Network error.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
            else if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            else if (_data != null)
              ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${_data!['teamEquipmentStatus'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('Class ID: ${_data!['classId']}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildRow('Equipment Name:', _data!['equipmentName']),
                _buildRow('Equipment Code:', _data!['equipmentCode']),
                _buildRow('Serial:', _data!['equipmentNumberSerial']),
                _buildRow('Team Name:', _data!['teamEquipmentName']),
                _buildRow('Class:', _data!['className']),
                _buildRow('Team:', _data!['teamName']),
                const Divider(),
                _buildRow('Borrow Time:', _data!['teamEquipmentDateBorrow']?.toString() ?? 'N/A'),
                _buildRow('Give Back Time:', _data!['teamEquipmentDateGiveBack']?.toString() ?? 'Not Returned'),
                _buildRow('Description:', _data!['teamEquipmentDescription']),
              ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
           Expanded(child: Text(value?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)))),
        ],
      ),
    );
  }
}
