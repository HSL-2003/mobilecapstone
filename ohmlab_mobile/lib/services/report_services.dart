import 'package:ohm_lab_mobile/services/api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> getTodaySlots() async {
    final response = await _apiService.defaultDio.get('/api/report/today-slots');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTodayClasses(String slotName) async {
    final response = await _apiService.defaultDio.get(
      '/api/report/today-classes',
      queryParameters: {'slotName': slotName},
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> createReport({
    required String title,
    required String description,
    required String slot,
    required String className,
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/report',
      data: {
        "reportTitle": title,
        "reportDescription": description,
        "selectedSlot": slot,
        "selectedClass": className,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> verifyEquipmentQR(String id, String qr) async {
    final response = await _apiService.defaultDio.post(
      '/api/equipment/qr',
      queryParameters: {
        'id': id,
        'QR': qr
      },
    );
    return ApiResponse.fromResponse(response);
  }
}

