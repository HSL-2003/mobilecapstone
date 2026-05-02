import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class LecturerCheckOutScreen extends StatefulWidget {
  const LecturerCheckOutScreen({super.key});

  @override
  State<LecturerCheckOutScreen> createState() => _LecturerCheckOutScreenState();
}

class _LecturerCheckOutScreenState extends State<LecturerCheckOutScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  // Cloudinary config (dùng chung với project backend)
  static const String _cloudName = 'dmm03xi29';
  static const String _uploadPreset = 'unsigned_checkout'; // Tạo Unsigned preset trên Cloudinary

  bool _isLoadingSchedules = true;
  bool _isUploading = false;
  String? _errorMessage;
  List<dynamic> _schedules = [];
  String? _lecturerId;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() { _isLoadingSchedules = true; _errorMessage = null; });
    try {
      final userRes = await _userService.getCurrentUser();
      if (userRes.status == 200 || userRes.status == 201) {
        final payload = userRes.data;
        final userData = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
        _lecturerId = userData['id']?.toString() ?? userData['userId']?.toString();

        if (_lecturerId != null) {
          final res = await _userService.getRegistrationSchedulesByTeacherId(_lecturerId!);
          if (res.status == 200 || res.status == 201) {
            final data = res.data;
            List<dynamic> all = data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : []);
            // Lọc lịch đang InProgress (đã check-in, đang sử dụng phòng)
            setState(() {
              _schedules = all.where((s) {
                final status = (s['registrationScheduleStatus'] ?? s['status'] ?? '').toString().toLowerCase();
                return status == 'inprogress' || status == 'in_progress' || status == 'in progress';
              }).toList();
              _isLoadingSchedules = false;
            });
          } else {
            setState(() { _errorMessage = 'Lỗi tải lịch: ${res.message}'; _isLoadingSchedules = false; });
          }
        }
      }
    } catch (e) {
      setState(() { _errorMessage = 'Error: $e'; _isLoadingSchedules = false; });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        'upload_preset': _uploadPreset,
        'folder': 'checkout_images',
      });

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String?;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
    }
    return null;
  }

  Future<void> _startCheckOut(Map<String, dynamic> schedule) async {
    final int? scheduleId = int.tryParse((schedule['registrationScheduleId'] ?? schedule['id'] ?? '').toString());
    if (scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID lịch.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Chọn nguồn ảnh
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Chọn ảnh Check-out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Chụp ảnh trả phòng để xác nhận', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildPickerOption(icon: Icons.camera_alt, label: 'Chụp ảnh', color: const Color(0xFFF26F21), onTap: () => Navigator.pop(ctx, ImageSource.camera))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPickerOption(icon: Icons.photo_library, label: 'Thư viện ảnh', color: Colors.blue, onTap: () => Navigator.pop(ctx, ImageSource.gallery))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1920);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload ảnh lên Cloudinary
      final String? imageUrl = await _uploadToCloudinary(File(pickedFile.path));

      if (imageUrl == null) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload ảnh thất bại. Kiểm tra lại Upload Preset trên Cloudinary.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Gọi API checkout với URL ảnh từ Cloudinary
      final res = await _userService.lecturerCheckOut(scheduleId, imageUrl);
      setState(() => _isUploading = false);

      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Check-out thành công! Lịch đã chuyển sang Completed.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _loadSchedules();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi check-out: ${res.message ?? res.status}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Check-out phòng Lab',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
              actions: [
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadSchedules),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingSchedules
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
              : _errorMessage != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
                  : _schedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('Không có lịch nào đang InProgress.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text('(Bảo vệ cần check-in trước)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 90, left: 20, right: 20, bottom: 24),
                          itemCount: _schedules.length,
                          itemBuilder: (context, index) {
                            final s = _schedules[index];
                            final String roomName = s['roomName'] ?? s['room']?['roomName'] ?? 'Phòng N/A';
                            final String date = s['registrationScheduleDate'] ?? s['date'] ?? 'N/A';
                            final String startTime = s['slotStartTime'] ?? s['startTime'] ?? '';
                            final String endTime = s['slotEndTime'] ?? s['endTime'] ?? '';
                            final String status = s['registrationScheduleStatus'] ?? s['status'] ?? 'N/A';
                            final String? existingImgUrl = s['registraionSchedule_Url_Img_Checkout']?.toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.meeting_room, color: Colors.blue, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(roomName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E1E1E))),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                                                  const SizedBox(width: 4),
                                                  Text('$date  $startTime-$endTime', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                          child: Text(status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                    if (existingImgUrl != null && existingImgUrl.isNotEmpty && existingImgUrl != 'null') ...[
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(existingImgUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _isUploading ? null : () => _startCheckOut(s),
                                        icon: _isUploading
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.camera_alt, size: 18),
                                        label: Text(
                                          _isUploading ? 'Uploading image...' : 'Check-out (Chụp ảnh trả phòng)',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[700],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
          // Loading overlay khi đang upload
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Đang upload ảnh lên Cloudinary...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
