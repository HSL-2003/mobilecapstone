import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse> loginGoogle(Map<String, dynamic> data) async {
    final response = await _apiService.defaultDio.post('/api/user/loginmail', data: data);
    _extractAndSaveToken(response.data);
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> loginTest(String email) async {
    final response = await _apiService.defaultDio.post('/api/user/logintest', queryParameters: {'email': email});
    _extractAndSaveToken(response.data);
    return ApiResponse.fromResponse(response);
  }

  void _extractAndSaveToken(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['token'] != null) {
        _saveToken(responseData['token']);
        _saveUserLocal(responseData);
      } else if (responseData['data'] is Map<String, dynamic> && responseData['data']['token'] != null) {
        _saveToken(responseData['data']['token']);
        _saveUserLocal(responseData['data']);
      }
    }
  }

  Future<void> _saveUserLocal(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToSave = Map<String, dynamic>.from(userData);
      userToSave.remove('token');
      await prefs.setString('currentUserData', jsonEncode(userToSave)); 
    } catch(e) {
      print('Error saving user: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('currentUserData');
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
    } catch(e) {
      print('Error parsing user: $e');
    }
    return null;
  }

  Future<ApiResponse> getCurrentUser() async {
    final response = await _apiService.skipAllNotiDio.get('/api/user/current-user');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getLecturerTeams(String lecturerId) async {
    final response = await _apiService.defaultDio.get('/api/team/lecturer/$lecturerId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getLecturerClasses(String lecturerId) async {
    final response = await _apiService.defaultDio.get('/api/class/lecturer/$lecturerId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getStudentClasses(String studentId) async {
    final response = await _apiService.defaultDio.get('/api/class/student/$studentId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getClassById(int classId) async {
    final response = await _apiService.defaultDio.get('/api/class/$classId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamsByClassId(int classId) async {
    final response = await _apiService.defaultDio.get('/api/team/class/$classId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> createTeam(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/team',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamUsers(int teamId) async {
    final response = await _apiService.defaultDio.get('/api/teamuser/team/$teamId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamUserById(int id) async {
    final response = await _apiService.skipNotiDio.get('/api/teamuser/$id');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> searchTeamEquipmentByLecturerId({
    required String lecturerId,
    int pageNum = 1,
    int pageSize = 100,
    String keyword = "",
    String status = "",
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamequipment/searchbylecturerid',
      data: {
        "pageNum": pageNum,
        "pageSize": pageSize,
        "lecturerId": lecturerId,
        "keyword": keyword.isEmpty ? null : keyword,
        "status": status.isEmpty ? null : status,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamEquipmentByTeamId(int teamId) async {
    final response = await _apiService.defaultDio.get('/api/teamequipment/listteamequipmentbyteamid/$teamId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> searchEquipment({
    int pageNum = 1,
    int pageSize = 100,
    String keyword = "",
    String status = "",
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/equipment/search',
      data: {
        "pageNum": pageNum,
        "pageSize": pageSize,
        "keyword": keyword.isEmpty ? null : keyword,
        "status": status.isEmpty ? null : status,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getEquipmentById(String equipmentId) async {
    final response = await _apiService.defaultDio.get('/api/equipment/$equipmentId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getKitById(String kitId) async {
    final response = await _apiService.defaultDio.get('/api/kit/$kitId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getRegistrationSchedulesByTeacherId(String teacherId) async {
    final response = await _apiService.defaultDio.get('/api/registrationschedule/listregistrationschedulebyteacherid/$teacherId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getRegistrationSchedulesByStudentId(String studentId) async {
    final response = await _apiService.defaultDio.get('/api/registrationschedule/student/$studentId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getAllRegistrationSchedules({String status = '', String keyword = ''}) async {
    final response = await _apiService.defaultDio.post(
      '/api/registrationschedule/search',
      data: {
        'pageNum': 1,
        'pageSize': 100,
        'keyword': keyword.isEmpty ? null : keyword,
        'status': status.isEmpty ? null : status,
        'date': null,
        'slotId': 0,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getRegistrationScheduleById(String id) async {
    final response = await _apiService.defaultDio.get('/api/registrationschedule/registrationschedule/$id');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamMembers(int teamId) async {
    final response = await _apiService.defaultDio.get('/api/teamuser/team/$teamId');
    return ApiResponse.fromResponse(response);
  }


  Future<ApiResponse> borrowEquipment(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamequipment/borrowequipment',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> giveBackEquipment(int teamEquipmentId) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamequipment/givebackequipment?teamEquipment=$teamEquipmentId',
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamEquipmentById(int id) async {
    final response = await _apiService.defaultDio.get('/api/teamequipment/$id');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> createRegistrationSchedule(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/registrationschedule/registrationschedule',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getGrade(int labId, int teamId) async {
    final response = await _apiService.defaultDio.get('/api/grade/labs/$labId/teams/$teamId/grade');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getGradeByTeamId(int teamId) async {
    final response = await _apiService.defaultDio.get('/api/grade/team/$teamId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getGradesByScheduleId(int scheduleId) async {
    final response = await _apiService.defaultDio.get('/api/grade/registration/$scheduleId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getMyGrades() async {
    final response = await _apiService.defaultDio.get(
      '/api/gradedescription/mygrade',
      options: Options(
        headers: {
          'accept': '*/*',
        },
      ),
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> submitGrade(int labId, int teamId, Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/grade/labs/$labId/teams/$teamId/grade', 
      data: payload
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> gradeForTeam(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/grade/gradeforteam',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> updateGrade(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.put(
      '/api/grade/update',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  // --- Kit Management APIs ---

  Future<ApiResponse> borrowKit(Map<String, dynamic> payload) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamkit/borrowkit',
      data: payload,
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> giveBackKit(int teamKitId) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamkit/givebackkit?teamKit=$teamKitId',
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamKitByTeamId(int teamId) async {
    final response = await _apiService.defaultDio.get('/api/teamkit/listteamkitteamid/$teamId');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> searchTeamKitByLecturerId({
    required String lecturerId,
    int pageNum = 1,
    int pageSize = 100,
    String keyword = "",
    String status = "",
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamkit/searchbylecturerid',
      data: {
        "pageNum": pageNum,
        "pageSize": pageSize,
        "lecturerId": lecturerId,
        "keyword": keyword.isEmpty ? null : keyword,
        "status": status.isEmpty ? null : status,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getTeamKitById(int id) async {
    final response = await _apiService.defaultDio.get('/api/teamkit/$id');
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> searchKits({
    int pageNum = 1,
    int pageSize = 100,
    String keyword = "",
    String status = "",
  }) async {
    final response = await _apiService.defaultDio.post(
      '/api/kit/search',
      data: {
        "pageNum": pageNum,
        "pageSize": pageSize,
        "keyword": keyword.isEmpty ? null : keyword,
        "status": status.isEmpty ? null : status,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> securityCheckIn(int registrationScheduleId) async {
    final response = await _apiService.defaultDio.post(
      '/api/security/checkin',
      data: {
        'registrationScheduleId': registrationScheduleId,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> securityUpdateStatusRoom(int registrationScheduleId) async {
    final response = await _apiService.defaultDio.post(
      '/api/security/updatastatusroom/$registrationScheduleId',
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> lecturerCheckOut(int registrationScheduleId, String imageUrl) async {
    final response = await _apiService.defaultDio.post(
      '/api/registrationschedule/lecturercheckout',
      data: {
        'registrationScheduleId': registrationScheduleId,
        'registraionSchedule_Url_Img_Checkout': imageUrl,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> addUsersToTeam(List<Map<String, dynamic>> listTeamUser) async {
    final response = await _apiService.defaultDio.post(
      '/api/teamuser/teamuser',
      data: {
        "listTeamUser": listTeamUser,
      },
    );
    return ApiResponse.fromResponse(response);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }
}