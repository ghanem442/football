import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_dashboard_model.dart';

class AdminRepository {
  final String baseUrl;
  final String token;

  AdminRepository({
    required this.baseUrl,
    required this.token,
  });

  Future<AdminDashboardModel> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    return AdminDashboardModel.fromJson(data['data']);
  }
}