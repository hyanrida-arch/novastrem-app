import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/novastream_logo.dart';

/// Sign-in entry point: lets the user connect NovaStream to an Xtream Codes
/// panel, a plain M3U playlist URL, or — via "Try Quick Demo Account" — a
/// built-in sample catalog that needs no server at all.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _xtreamFormKey = GlobalKey<FormState>();
  final _m3uFormKey = GlobalKey<FormState>();

  final _xtreamProfileNameController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _m3uUrlController = TextEditingController();
  final _playlistNameController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _xtreamProfileNameController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    _playlistNameController.dispose();
    super.dispose();
  }

  void _submitXtream() {
    if (!_xtreamFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).loginWithXtream(
          serverUrl: _serverUrlController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  void _submitM3u() {
    if (!_m3uFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).loginWithM3u(
          m3uUrl: _m3uUrlController.text,
          playlistName: _playlistNameController.text,
        );
  }

  void _submitDemo() {
    ref.read(authControllerProvider.notifier).loginDemo();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        // Straight into catalog preparation — the dashboard should only
        // ever open on data that's already fetched and sorted.
        Navigator.of(context).pushReplacementNamed(AppRoutes.initializing);
      } else if (next.status == AuthStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? AppStrings.loginError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final isLoading = ref.watch(authControllerProvider).status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: NovaStreamLogo(size: 68)),
                  const SizedBox(height: 18),
                  const Text(
                    AppStrings.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  _DemoAccountCard(onTap: isLoading ? null : _submitDemo),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      // The app-wide TabBarTheme paints selected labels in
                      // AppColors.primary, which is exactly the color this
                      // pill indicator is filled with — leaving the active
                      // tab's text invisible. Override to white here.
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      tabs: const [
                        Tab(text: AppStrings.loginXtreamTab),
                        Tab(text: AppStrings.loginM3uTab),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildXtreamForm(isLoading)
                              : _buildM3uForm(isLoading);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXtreamForm(bool isLoading) {
    return Form(
      key: _xtreamFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _xtreamProfileNameController,
            decoration: const InputDecoration(
              labelText: AppStrings.fieldProfileName,
              prefixIcon: Icon(Icons.tv_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _serverUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: AppStrings.fieldServerUrl,
              hintText: AppStrings.fieldServerUrlHint,
              prefixIcon: Icon(Icons.dns_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Server URL is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: AppStrings.fieldUsername,
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: AppStrings.fieldPassword,
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
          ),
          const SizedBox(height: 22),
          _SubmitButton(
            label: AppStrings.buttonConnectXtream,
            isLoading: isLoading,
            onPressed: isLoading ? null : _submitXtream,
          ),
        ],
      ),
    );
  }

  Widget _buildM3uForm(bool isLoading) {
    return Form(
      key: _m3uFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _playlistNameController,
            decoration: const InputDecoration(
              labelText: AppStrings.fieldPlaylistName,
              prefixIcon: Icon(Icons.playlist_play_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _m3uUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: AppStrings.fieldM3uUrl,
              hintText: AppStrings.fieldM3uUrlHint,
              prefixIcon: Icon(Icons.link_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'M3U URL is required' : null,
          ),
          const SizedBox(height: 22),
          _SubmitButton(
            label: AppStrings.buttonConnectM3u,
            isLoading: isLoading,
            onPressed: isLoading ? null : _submitM3u,
          ),
        ],
      ),
    );
  }
}

/// "Try Quick Demo Account" — a tappable card, styled like the rest of the
/// app (dark surface, brand-gradient icon badge) rather than a plain button,
/// since it's the fastest path into the app and deserves top billing.
class _DemoAccountCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _DemoAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.demoAccountTitle,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    SizedBox(height: 3),
                    Text(
                      AppStrings.demoAccountSubtitle,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SubmitButton({required this.label, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label, style: const TextStyle(letterSpacing: 0.4)),
    );
  }
}
