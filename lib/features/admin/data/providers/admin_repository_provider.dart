import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  // عدل baseUrl حسب مشروعك
  const baseUrl = "https://your-api-url.com/api/v1";

  // لاحقًا هنجيب التوكن من auth provider
  const token = "";

  return AdminRepository(
    baseUrl: baseUrl,
    token: token,
  );
});