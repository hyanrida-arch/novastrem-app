import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/user_login_entity.dart';
import '../../../auth/presentation/logout_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Account/profile screen: a card-based summary of whatever the user is
/// currently signed in with. Xtream Codes sessions get the full subscription
/// panel (status, expiry, connections, server); M3U and Demo sessions show
/// a simpler card, since Xtream is the only login type with that metadata
/// to display — see [UserLoginEntity], which already carries everything
/// shown here (parsed once, at login time, in `AuthRepositoryImpl`).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;

    return GlassScaffold(
      title: const Text('Profile'),
      body: session == null
          ? const Center(child: Text('Not signed in.'))
          // Builder so `MediaQuery.paddingOf` sees GlassScaffold's injected
          // top inset; this list sets its own padding.
          : Builder(
              builder: (context) => ListView(
              padding: const EdgeInsets.all(20)
                  .copyWith(top: MediaQuery.paddingOf(context).top + 20),
              children: [
                _ProfileHeaderCard(session: session),
                const SizedBox(height: 20),
                if (session.isXtream) _XtreamDetailsCard(session: session),
                if (session.isDemo) const _InfoCard(
                  icon: Icons.play_circle_outline_rounded,
                  text: "You're exploring NovaStream's built-in sample catalog. "
                      'Sign in with a real Xtream Codes or M3U account for live data.',
                ),
                if (!session.isXtream && !session.isDemo && session.m3uUrl != null)
                  _InfoCard(icon: Icons.link_rounded, text: session.m3uUrl!),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(AppStrings.logout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => confirmLogout(context, ref),
                  ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final UserLoginEntity session;
  const _ProfileHeaderCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              session.playlistName.isNotEmpty ? session.playlistName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.playlistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (session.isXtream && session.status != null)
                  _StatusBadge(status: session.status!)
                else
                  Text(
                    session.isDemo ? 'Quick Demo Account' : 'M3U Playlist',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'expired':
        return AppColors.warning;
      case 'banned':
      case 'disabled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _XtreamDetailsCard extends StatelessWidget {
  final UserLoginEntity session;
  const _XtreamDetailsCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: session.username ?? '—',
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.event_busy_rounded,
            label: 'Expiration Date',
            value: formatExpiryDate(session.expiryDate),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.podcasts_rounded,
            label: 'Connections',
            value: '${session.activeConnections ?? 0} / ${session.maxConnections ?? '∞'} active',
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.dns_rounded,
            label: 'Server URL',
            value: session.serverUrl ?? '—',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
