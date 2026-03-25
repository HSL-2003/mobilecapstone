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
    if (response.data is Map<String, dynamic> && response.data['token'] != null) {
      await _saveToken(response.data['token']);
    }
    return ApiResponse.fromResponse(response);
  }

  Future<ApiResponse> getCurrentUser() async {
    final response = await _apiService.skipAllNotiDio.get('/api/user/current-user');
    return ApiResponse.fromResponse(response);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }
}