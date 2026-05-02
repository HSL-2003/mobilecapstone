import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';
import 'package:flutter/services.dart';

class CommonReportHistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  const CommonReportHistoryScreen({super.key, this.hideAppBar = false});

  @override
  State<CommonReportHistoryScreen> createState() => _CommonReportHistoryScreenState();
}

class _CommonReportHistoryScreenState extends State<CommonReportHistoryScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reportHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final res = await _reportService.getMyReports();
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (res.data is Map && res.data.containsKey('data')) {
              final payload = res.data['data'];
              if (payload is Map && payload.containsKey('reports')) {
                _reportHistory = payload['reports'] is List ? payload['reports'] : [];
              } else if (payload is List) {
                _reportHistory = payload;
              }
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = res.message ?? "Lỗi tải lịch sử báo cáo.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Server connection error.";
        });
      }
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
              title: const Text('Lịch sử báo cáo', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95), // Orange tint
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchReports();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportHistory.isEmpty) {
      return const Center(child: Text("Chưa có bất kỳ báo cáo nào.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
              padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, left: 24, right: 24, bottom: 24),
              itemCount: _reportHistory.length,
              itemBuilder: (context, index) {
                final report = _reportHistory[index];
                
                final String idStr = report['id']?.toString() ?? 'N/A';
                final String dateStr = report['createdDate']?.toString() ?? report['reportDate']?.toString() ?? 'Unknown Date';
                final String classStr = report['className']?.toString() ?? 'N/A';
                final String slotStr = report['slot']?.toString() ?? '';
                final String categoryStr = report['categoryName']?.toString() ?? report['reportCategory']?.toString() ?? 'Other';
                final String equipStr = report['equipmentName']?.toString() ?? report['equipment']?.toString() ?? '';
                final String statusStr = report['status']?.toString() ?? 'Pending';
                
                Color statusColor = Colors.orange;
                if (statusStr.toLowerCase().contains('done') || statusStr.toLowerCase().contains('xử lý')) {
                  statusColor = Colors.green;
                } else if (statusStr.toLowerCase().contains('reject')) {
                  statusColor = Colors.red;
                }

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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt_long, color: Color(0xFFF26F21), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr, 
                               style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              statusStr,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Ngày gửi', dateStr),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.class_outlined, 'Class', '$classStr - $slotStr'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.warning_amber_rounded, 'Sự cố', categoryStr),
                      if (equipStr.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.qr_code_scanner, 'Equipment', equipStr),
                      ]
                    ],
                  ),
                );
              },
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
}
