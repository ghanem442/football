import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_theme.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String _extractMessage(dynamic raw) {
    if (raw is Map) {
      final error = raw['error'];

      if (error is Map) {
        final msg = error['message'];

        if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }

        if (msg is Map) {
          final ar = msg['ar']?.toString().trim();
          final en = msg['en']?.toString().trim();

          if (ar != null && ar.isNotEmpty) return ar;
          if (en != null && en.isNotEmpty) return en;
        }

        if (msg is List && msg.isNotEmpty) {
          return msg.join('\n');
        }
      }

      final message = raw['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is Map) {
        final ar = message['ar']?.toString().trim();
        final en = message['en']?.toString().trim();

        if (ar != null && ar.isNotEmpty) return ar;
        if (en != null && en.isNotEmpty) return en;
      }

      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }
    }

    return 'Request failed';
  }

  Future<void> _submit() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final api = ref.read(apiClientProvider);

      final res = await api.post(
        'auth/forgot-password',
        data: {'email': email},
      );

      final raw = res.data;
      final statusCode = res.statusCode;
      final isOk =
          statusCode != null &&
          statusCode < 400 &&
          raw is Map &&
          (raw['success'] == true || raw['success'] == null);

      final msg = isOk
          ? _extractMessage(raw).replaceAll('Request failed', '')
          : _extractMessage(raw);

      if (!mounted) return;

      if (!isOk) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg.isEmpty ? 'Failed to send code' : msg)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty
                ? msg
                : 'If an account exists, a reset code has been sent.',
          ),
        ),
      );

      await context.push('/reset-password', extra: email);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send code: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.lock_reset, size: 64, color: AppColors.orange),
            const SizedBox(height: 12),
            const Text(
              'Reset your password',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we will send you a 6-digit verification code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkSubText : AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_loading) {
                  _submit();
                }
              },
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}