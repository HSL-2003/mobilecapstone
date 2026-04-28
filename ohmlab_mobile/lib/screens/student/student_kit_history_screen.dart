import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class StudentKitHistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  final int? teamId;
  const StudentKitHistoryScreen({super.key, this.hideAppBar = false, this.teamId});

  @override
  State<StudentKitHistoryScreen> createState() => _StudentKitHistoryScreenState();
}

class _StudentKitHistoryScreenState extends State<StudentKitHistoryScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _kitHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      int? effectiveTeamId = widget.teamId;

      if (effectiveTeamId == null) {
        final userResponse = await _userService.getCurrentUser();
        if (userResponse.status == 200 || userResponse.status == 201) {
          final payload = userResponse.data;
          final userData = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
          final rawId = userData['teamId'] ?? userData['studentTeamId'] ?? userData['team']?['id'];
          effectiveTeamId = int.tryParse(rawId?.toString() ?? '');
        }
      }

      if (effectiveTeamId != null) {
        final histResponse = await _userService.getTeamKitByTeamId(effectiveTeamId);
        if (histResponse.status == 200 || histResponse.status == 201) {
          if (mounted) {
            setState(() {
              final histPayload = histResponse.data;
              dynamic dataItems = histPayload is Map && histPayload.containsKey('data') ? histPayload['data'] : histPayload;
              _kitHistory = dataItems is List ? dataItems : [];
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() { _errorMessage = 'Không thể tải lịch sử Kit của nhóm.'; _isLoading = false; });
        }
      } else {
        if (mounted) setState(() { _errorMessage = 'Hãy vào "Danh sách Team" để xem lịch sử của nhóm bạn.'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Lỗi: $e'; _isLoading = false; });
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
              title: const Text('Lịch sử Kit', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
        : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))))
          : _kitHistory.isEmpty
            ? const Center(child: Text("Nhóm chưa có lịch sử mượn trả Kit.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, left: 24, right: 24, bottom: 24),
                itemCount: _kitHistory.length,
                itemBuilder: (context, index) {
                  final hist = _kitHistory[index];
                  
                  final String rawBorrowDate = hist['teamKitDateBorrow']?.toString() ?? '';
                  String displayDate = 'N/A';
                  String borrowTime = 'N/A';
                  if (rawBorrowDate.isNotEmpty && rawBorrowDate != 'null') {
                    try {
                      final dt = DateTime.parse(rawBorrowDate).toLocal();
                      displayDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                      borrowTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final String rawGiveBackDate = hist['teamKitDateGiveBack']?.toString() ?? '';
                  String? returnTime;
                  if (rawGiveBackDate.isNotEmpty && rawGiveBackDate != 'null') {
                    try {
                      final dt = DateTime.parse(rawGiveBackDate).toLocal();
                      returnTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  final String teamName = hist['teamName']?.toString() ?? 'Nhóm';
                  final String className = hist['className']?.toString() ?? '';
                  final String kitName = hist['kitName']?.toString() ?? 'Kit';
                  final String kitCode = hist['kitId']?.toString() ?? hist['kitCode']?.toString() ?? '-';
                   final String? kitImgUrl = hist['kitImgUrl']?.toString();
                  
                  final String rawStatus = hist['teamKitStatus']?.toString() ?? 'Unknown';
                  final String status = rawStatus == 'AreBorrowing' ? 'Đang sử dụng' : (rawStatus == 'GiveBack' ? 'Đã trả' : (rawStatus == 'Paid' ? 'Đã trả' : rawStatus));
                  final Color statusColor = (status == 'Đã trả') ? Colors.green : Colors.orange;
                  
                  final int? teamKitId = int.tryParse(hist['teamKitId']?.toString() ?? '');

                  return Container(
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
                                if (kitImgUrl != null && kitImgUrl.isNotEmpty && kitImgUrl != 'null')
                                  Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(image: NetworkImage(kitImgUrl), fit: BoxFit.cover),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.inventory_2, color: Color(0xFFF26F21), size: 18),
                                  ),
                                Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.group_outlined, 'Lớp/Nhóm', '$className - $teamName'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.developer_board, 'Kit', '$kitName ($kitCode)'),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeBadge(Icons.call_made, 'Mượn: $borrowTime', Colors.blue),
                              if (returnTime != null && returnTime.isNotEmpty && returnTime != 'null')
                                _buildTimeBadge(Icons.call_received, 'Trả: $returnTime', Colors.green)
                              else
                                _buildTimeBadge(Icons.timer, 'Chưa trả', Colors.orange),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
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
