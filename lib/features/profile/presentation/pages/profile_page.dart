import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _normalizedRole(String? role) {
    return (role ?? '').trim().toUpperCase();
  }

  String _roleLabel(String? role) {
    switch (_normalizedRole(role)) {
      case 'FIELD_OWNER':
        return 'Field Owner';
      case 'PLAYER':
        return 'Player';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'User';
    }
  }

  String _roleSubtitle(String? role) {
    switch (_normalizedRole(role)) {
      case 'FIELD_OWNER':
        return 'Manage your fields, bookings & wallet';
      case 'PLAYER':
        return 'Manage your bookings & wallet';
      case 'ADMIN':
        return 'Manage platform access';
      default:
        return 'Manage your account';
    }
  }

  bool _isPlayer(String? role) => _normalizedRole(role) == 'PLAYER';
  bool _isOwner(String? role) => _normalizedRole(role) == 'FIELD_OWNER';
  bool _isAdmin(String? role) => _normalizedRole(role) == 'ADMIN';

  String _homeRouteForRole(String? role) {
    if (_isAdmin(role)) return '/admin/dashboard';
    if (_isOwner(role)) return '/owner';
    return '/home';
  }

  String _walletRouteForRole(String? role) {
    if (_isAdmin(role)) return '/admin/wallet';
    if (_isOwner(role)) return '/owner/wallet';
    return '/wallet';
  }

  String _bookingsRouteForRole(String? role) {
    if (_isOwner(role)) return '/owner/bookings';
    return '/my-bookings';
  }

  String _bookingsLabelForRole(String? role) {
    if (_isOwner(role)) return 'Owner Bookings';
    if (_isAdmin(role)) return 'Platform Bookings';
    return 'My Bookings';
  }

  String _browseLabelForRole(String? role) {
    if (_isAdmin(role)) return 'Dashboard';
    if (_isOwner(role)) return 'My Fields';
    return 'Browse Fields';
  }

  IconData _browseIconForRole(String? role) {
    if (_isAdmin(role)) return Icons.admin_panel_settings_outlined;
    if (_isOwner(role)) return Icons.storefront_outlined;
    return Icons.stadium_outlined;
  }

  Future<void> _refreshForRole(WidgetRef ref, String? role) async {
    if (_isPlayer(role)) {
      try {
        await ref.read(walletProvider.notifier).refreshWallet();
      } catch (_) {
        ref.invalidate(walletProvider);
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(authSessionProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final authUser = ref.watch(authUserProvider);

    final name = authUser?.name?.trim();
    final email = authUser?.email.trim() ?? '';
    final role = authUser?.role;
    final isVerified = authUser?.isVerified ?? false;

    final isPlayer = _isPlayer(role);
    final walletAsync = isPlayer ? ref.watch(walletProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home),
            onPressed: () => context.go(_homeRouteForRole(role)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshForRole(ref, role),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).dividerColor.withAlpha(60),
                      child: const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (name != null && name.isNotEmpty)
                                ? name
                                : _roleLabel(role),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : 'No email available',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                icon: Icons.badge_outlined,
                                label: _roleLabel(role),
                              ),
                              _InfoChip(
                                icon: isVerified
                                    ? Icons.verified_outlined
                                    : Icons.error_outline,
                                label: isVerified ? 'Verified' : 'Not Verified',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_roleSubtitle(role)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _refreshForRole(ref, role),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text(
                  'Wallet',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: isPlayer
                    ? walletAsync!.when(
                        loading: () => const Text('Loading balance...'),
                        error: (e, _) => const Text('Failed to load balance'),
                        data: (w) => Text(
                          'Balance: ${w.balance.toStringAsFixed(2)} EGP',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : Text(
                        _isAdmin(role)
                            ? 'Open admin wallet dashboard'
                            : 'Open owner wallet dashboard',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(_walletRouteForRole(role)),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  _isOwner(role) ? Icons.event_note : Icons.list_alt,
                ),
                title: Text(
                  _bookingsLabelForRole(role),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (_isAdmin(role)) {
                    context.go('/admin/bookings');
                    return;
                  }
                  context.go(_bookingsRouteForRole(role));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                value: mode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                secondary: Icon(
                  mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
                onTap: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(_homeRouteForRole(role)),
                    icon: Icon(_browseIconForRole(role)),
                    label: Text(_browseLabelForRole(role)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_isAdmin(role)) {
                        context.go('/admin/bookings');
                        return;
                      }
                      context.go(_bookingsRouteForRole(role));
                    },
                    icon: const Icon(Icons.event_note),
                    label: Text(_bookingsLabelForRole(role)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).dividerColor.withAlpha(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}