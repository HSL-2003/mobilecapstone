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
    required int registraionScheduleId,
    required String equipmentId,
    required String urlImg,
    required String reportTitle,
    required String reportDescription,
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/report',
      data: {
        "registraionScheduleId": registraionScheduleId,
        "equipmentId": equipmentId,
        "url_Img": urlImg,
        "reportTitle": reportTitle,
        "reportDescription": reportDescription,
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

  Future<ApiResponse> verifyKitQR(String id, String qr) async {
    final response = await _apiService.defaultDio.post(
      '/api/kit/qr',
      queryParameters: {
        'id': id,
        'QR': qr
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getMyReports() async {
    final response = await _apiService.defaultDio.get('/api/report/my-reports');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> searchEquipments() async {
    final response = await _apiService.defaultDio.post(
      '/api/equipment/search',
      data: {
        "pageNum": 1,
        "pageSize": 1000,
        "keyWord": "",
        "status": ""
      },
    );
    return ApiResponse.fromResponse(response);
  }
}

