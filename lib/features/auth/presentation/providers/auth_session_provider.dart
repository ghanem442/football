import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/storage/providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final accessTokenProvider = StateProvider<String?>((ref) => null);
final refreshTokenProvider = StateProvider<String?>((ref) => null);

@immutable
class AuthUser {
  const AuthUser({
    required this.email,
    required this.isVerified,
    this.name,
    this.role,
    this.id,
  });

  final String email;
  final bool isVerified;
  final String? name;
  final String? role;
  final String? id;

  AuthUser copyWith({
    String? email,
    bool? isVerified,
    String? name,
    String? role,
    String? id,
  }) {
    return AuthUser(
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      name: name ?? this.name,
      role: role ?? this.role,
      id: id ?? this.id,
    );
  }
}

final authUserProvider = StateProvider<AuthUser?>((ref) => null);

final authIsVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(authUserProvider.select((u) => u?.isVerified ?? true));
});

final authEmailProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider.select((u) => u?.email));
});

final authUserNameProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider.select((u) => u?.name));
});

final authUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider.select((u) => u?.role));
});

class AuthSession extends Notifier<AuthStatus> {
  static const _bootTimeout = Duration(seconds: 2);

  @override
  AuthStatus build() => AuthStatus.unknown;

  Future<void> boot() async {
    final storage = ref.read(secureStorageProvider);

    try {
      final accessFuture = storage.getAccessToken();
      final refreshFuture = storage.getRefreshToken();

      final access = await accessFuture.timeout(_bootTimeout);
      final refresh = await refreshFuture.timeout(_bootTimeout);

      final accessOk = access != null && access.trim().isNotEmpty;
      final refreshOk = refresh != null && refresh.trim().isNotEmpty;

      ref.read(accessTokenProvider.notifier).state = accessOk ? access : null;
      ref.read(refreshTokenProvider.notifier).state = refreshOk ? refresh : null;

      if (accessOk) {
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
        ref.read(authUserProvider.notifier).state = null;
      }

      if (kDebugMode) {
        debugPrint(
          'Auth boot done. access=${accessOk ? "YES" : "NO"} refresh=${refreshOk ? "YES" : "NO"} status=$state',
        );
      }
    } catch (e) {
      ref.read(accessTokenProvider.notifier).state = null;
      ref.read(refreshTokenProvider.notifier).state = null;
      ref.read(authUserProvider.notifier).state = null;

      state = AuthStatus.unauthenticated;

      if (kDebugMode) {
        debugPrint('Auth boot failed -> unauthenticated. Error: $e');
      }
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final storage = ref.read(secureStorageProvider);

    await storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    ref.read(accessTokenProvider.notifier).state = accessToken;
    ref.read(refreshTokenProvider.notifier).state = refreshToken;

    state = AuthStatus.authenticated;
  }

  void saveUser({
    required String email,
    required bool isVerified,
    String? name,
    String? role,
    String? id,
  }) {
    ref.read(authUserProvider.notifier).state = AuthUser(
      email: email.trim(),
      isVerified: isVerified,
      name: name?.trim(),
      role: role,
      id: id,
    );
  }

  void setUserFromAuthResponse(Map<String, dynamic> data) {
    final userMap = (data['user'] is Map) ? (data['user'] as Map) : null;
    if (userMap == null) return;

    final email = (userMap['email'] ?? '').toString().trim();
    if (email.isEmpty) return;

    final name = userMap['name']?.toString().trim();
    final isVerified = userMap['isVerified'] == true;
    final role = userMap['role']?.toString();
    final id = userMap['id']?.toString();

    saveUser(
      email: email,
      isVerified: isVerified,
      name: (name != null && name.isNotEmpty) ? name : null,
      role: role,
      id: id,
    );
  }

  void markVerified() {
    final current = ref.read(authUserProvider);
    if (current == null) return;

    ref.read(authUserProvider.notifier).state =
        current.copyWith(isVerified: true);
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);

    await storage.clearTokens();

    ref.read(accessTokenProvider.notifier).state = null;
    ref.read(refreshTokenProvider.notifier).state = null;
    ref.read(authUserProvider.notifier).state = null;

    state = AuthStatus.unauthenticated;
  }

  void markAuthenticated() {
    state = AuthStatus.authenticated;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSession, AuthStatus>(AuthSession.new);